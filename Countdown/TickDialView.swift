//
//  TickDialView.swift
//  Countdown
//
//  A radial tick-mark dial drawn with Core Graphics instead of pre-rendered
//  PNGs. Ticks fill clockwise from the top up to the current value; the tick at
//  the value is the accent "selected" mark, drawn with an animation whose style
//  is configurable (see SelectStyle). The ring can also sweep in from empty on
//  appear.
//

import UIKit
import QuartzCore

@IBDesignable
final class TickDialView: UIView {

    // MARK: - Selected-tick styles

    enum SelectStyle: String, CaseIterable {
        case classic, launch, eject, rippleIn, wake, rippleWake

        var title: String {
            switch self {
            case .classic:    return "Classic"
            case .launch:     return "Launch"
            case .eject:      return "Eject"
            case .rippleIn:   return "Ripple In"
            case .wake:       return "Wake"
            case .rippleWake: return "Ripple In + Wake"
            }
        }
    }

    /// The persisted, app-wide style. Every dial reads the same setting.
    static var savedStyle: SelectStyle {
        get { SelectStyle(rawValue: UserDefaults.standard.string(forKey: "tickStyle") ?? "") ?? .wake }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "tickStyle") }
    }

    // MARK: - Configuration

    /// Number of ticks around the ring (24 for hours, 60 for minutes/seconds).
    @IBInspectable var total: Int = 60 { didSet { setNeedsDisplay() } }

    var selectStyle: SelectStyle = TickDialView.savedStyle { didSet { setNeedsDisplay() } }

    @IBInspectable var filledColor: UIColor = UIColor(white: 0.592, alpha: 0.9) { didSet { setNeedsDisplay() } }
    @IBInspectable var trackColor: UIColor = UIColor(white: 0.592, alpha: 0.14) { didSet { setNeedsDisplay() } }
    @IBInspectable var accentColor: UIColor = UIColor(red: 0.749, green: 0.910, blue: 0.984, alpha: 1) { didSet { setNeedsDisplay() } }

    @IBInspectable var tickWidth: CGFloat = 2.7 { didSet { setNeedsDisplay() } }
    @IBInspectable var tickLengthRatio: CGFloat = 0.15 { didSet { setNeedsDisplay() } }

    /// How many past ticks carry the Wake glow.
    private let wakeLength = 7

    // MARK: - Value

    var value: Int = 0 {
        didSet {
            guard value != oldValue else { return }
            previousValue = oldValue
            if isSweeping { return }                 // the sweep owns the visuals
            renderValue = CGFloat(clampedValue)      // snap the fill
            beginSelectionPhase()                    // animate the accent tick per style
        }
    }

    private var clampedValue: Int { max(0, min(value, total)) }

    // MARK: - Animation state

    private var renderValue: CGFloat = 0             // fractional fill extent (during sweep)
    private var previousValue: Int = 0               // for Eject

    private var selectionPhase: CGFloat = 1          // 0 = just landed, 1 = settled
    private var phaseStart: CFTimeInterval = 0
    private var selectionDuration: CFTimeInterval = 0.6

    private var isSweeping = false
    private var sweepFrom: CGFloat = 0
    private var sweepTo: CGFloat = 0
    private var sweepStart: CFTimeInterval = 0
    private var sweepDuration: CFTimeInterval = 0.8

    private var link: CADisplayLink?

    // MARK: - Init

    override init(frame: CGRect) { super.init(frame: frame); commonInit() }
    required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
        renderValue = CGFloat(clampedValue)
    }

    deinit { link?.invalidate() }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil { link?.invalidate(); link = nil }   // don't animate off-screen
    }

    // MARK: - Public API

    /// Sweep the ring up from empty to `newValue`. Use on appear / on a new date.
    func sweepIn(to newValue: Int, duration: TimeInterval = 0.8) {
        let target = max(0, min(newValue, total))
        guard window != nil, duration > 0 else {
            isSweeping = false
            value = newValue
            renderValue = CGFloat(target)
            setNeedsDisplay()
            return
        }
        isSweeping = true
        sweepFrom = 0
        sweepTo = CGFloat(target)
        sweepStart = CACurrentMediaTime()
        sweepDuration = duration
        renderValue = 0
        value = newValue            // didSet returns early while isSweeping
        ensureLink()
    }

    // MARK: - Driving the animation

    private func beginSelectionPhase() {
        selectionDuration = duration(for: selectStyle)
        guard window != nil else { selectionPhase = 1; setNeedsDisplay(); return }
        phaseStart = CACurrentMediaTime()
        selectionPhase = 0
        ensureLink()
    }

    private func ensureLink() {
        guard link == nil else { return }
        let l = CADisplayLink(target: self, selector: #selector(step))
        l.add(to: .main, forMode: .common)
        link = l
    }

    @objc private func step(_ link: CADisplayLink) {
        let now = CACurrentMediaTime()
        var active = false

        if isSweeping {
            let t = min(1, (now - sweepStart) / sweepDuration)
            renderValue = sweepFrom + (sweepTo - sweepFrom) * easeInOut(CGFloat(t))
            if t >= 1 { isSweeping = false; renderValue = sweepTo } else { active = true }
        }

        let ts = (now - phaseStart) / selectionDuration
        selectionPhase = CGFloat(min(1, ts))
        if ts < 1 { active = true }

        setNeedsDisplay()
        if !active { link.invalidate(); self.link = nil }
    }

    private func duration(for style: SelectStyle) -> CFTimeInterval {
        switch style {
        case .classic:              return 0.3
        case .launch:               return 0.6
        case .eject:                return 0.66
        case .rippleIn:             return 0.7
        case .wake, .rippleWake:    return 0.6
        }
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard total > 0 else { return }

        let cx = rect.midX, cy = rect.midY
        let outer = min(rect.width, rect.height) / 2 - tickWidth
        let inner = outer - outer * tickLengthRatio
        let stepAngle = 2 * CGFloat.pi / CGFloat(total)

        let sel = clampedValue
        let filledUpTo = Int(renderValue.rounded(.down))
        let frac = renderValue - CGFloat(filledUpTo)
        let p = selectionPhase

        func angleAt(_ f: CGFloat) -> CGFloat { -CGFloat.pi / 2 + f * stepAngle }
        func mark(_ angle: CGFloat, _ r0: CGFloat, _ r1: CGFloat, _ color: UIColor, _ w: CGFloat) {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: cx + cos(angle) * r0, y: cy + sin(angle) * r0))
            path.addLine(to: CGPoint(x: cx + cos(angle) * r1, y: cy + sin(angle) * r1))
            path.lineCapStyle = .round
            path.lineWidth = w
            color.setStroke()
            path.stroke()
        }

        for i in 0..<total {
            let ang = angleAt(CGFloat(i))
            var r0 = inner, r1 = outer, w = tickWidth
            var color: UIColor = (i < filledUpTo) ? filledColor : trackColor

            // Leading partial tick while sweeping in.
            if isSweeping && i == filledUpTo {
                color = accentColor.withAlphaComponent(frac <= 0.01 ? 1 : frac)
                w = tickWidth + 0.6
            }

            // The selected accent tick, rendered per style.
            if !isSweeping && i == sel {
                switch selectStyle {
                case .launch:
                    let s = easeOutBack(p)
                    r0 = inner * s; r1 = outer * s
                    color = accentColor.withAlphaComponent(min(1, p * 3)); w = tickWidth + 0.6
                case .eject:
                    let pop = easeOutBack(min(1, p * 1.4))
                    r1 = inner + (outer - inner) * pop
                    color = accentColor; w = tickWidth + 0.7
                case .wake, .rippleWake:
                    color = accentColor.withAlphaComponent(0.85 + 0.15 * easeOutCubic(p)); w = tickWidth + 0.5
                case .rippleIn:
                    color = accentColor.withAlphaComponent(min(1, 0.4 + p)); w = tickWidth + 0.5
                case .classic:
                    color = accentColor; w = tickWidth + 0.5
                }
            }

            // Wake: a soft accent glow on the recent past, fading as it recedes.
            if !isSweeping && i != sel && (selectStyle == .wake || selectStyle == .rippleWake) {
                var k = sel - i; if k < 0 { k += total }         // 0 at current, grows into the past
                if k <= wakeLength {
                    var g = pow(1 - CGFloat(k) / CGFloat(wakeLength), 1.6) * 0.5
                    if k == 0 { g *= (0.6 + 0.4 * p) }
                    if g > 0.02 { color = accentColor.withAlphaComponent(g); w = tickWidth + 0.1 }
                }
            }

            // Ripple In: a faint front sweeps in from the UPCOMING side. Its crest
            // travels from the far ticks past the center, so once it settles every
            // upcoming tick is back to its original color and only the current tick
            // stays blue.
            if !isSweeping && i != sel && (selectStyle == .rippleIn || selectStyle == .rippleWake) {
                var a = (i - sel) % total; if a < 0 { a += total }  // 0 at current, grows into the future
                if a >= 1 && a <= 9 {
                    let front = 7 - easeOutCubic(p) * 10          // 7 (far upcoming) -> -3 (past center)
                    let sig: CGFloat = 1.4
                    let inten = exp(-pow(CGFloat(a) - front, 2) / (2 * sig * sig)) * 0.55
                    if inten > 0.03 {
                        r1 = outer + inten * 4
                        color = accentColor.withAlphaComponent(min(0.55, inten))
                        w = tickWidth + 0.1
                    }
                }
            }

            mark(ang, r0, r1, color, w)
        }

        // Eject: fragments of the previous tick flying outward.
        if !isSweeping && selectStyle == .eject {
            let off = easeOutCubic(p) * 36
            for f in -1...1 {
                let ea = angleAt(CGFloat(previousValue)) + CGFloat(f) * 0.05
                let al = (1 - p) * (f == 0 ? 0.9 : 0.55)
                if al > 0.02 { mark(ea, inner + off, outer + off, accentColor.withAlphaComponent(al), f == 0 ? 3 : 2.2) }
            }
        }
    }

    // MARK: - Easing

    private func easeInOut(_ t: CGFloat) -> CGFloat { t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2 }
    private func easeOutCubic(_ t: CGFloat) -> CGFloat { 1 - pow(1 - t, 3) }
    private func easeOutBack(_ t: CGFloat) -> CGFloat {
        let c1: CGFloat = 1.70158, c3 = c1 + 1
        return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setNeedsDisplay()
    }
}
