//
//  TickDialView.swift
//  Countdown
//
//  A single-ring radial tick dial drawn with Core Graphics. Ticks fill
//  clockwise from the top up to the current value; the tick at the value is
//  the accent mark. Two families of animation play on the ring, both selectable
//  in settings and implemented once in the shared `DialRing` renderer:
//
//   • Refill styles — how the filled ticks *arrive* when the ring refills
//     (on appear, on rollover, on a date edit). Five choices, default volley.
//   • Tick-pass styles — how the just-passed tick *exits* each second. Five
//     choices, default none (an instant flip to track).
//
//  The mechanics are style-agnostic: Ledger / Editorial / T-Minus supply only
//  their own colors; the geometry below is identical everywhere.
//

import UIKit
import QuartzCore

// MARK: - Selectable animation styles

/// How a ring's filled ticks arrive when it refills. Persisted under
/// `"refillStyle"`; see `DialRing` for each style's geometry.
enum RefillStyle: String, CaseIterable {
    case volley, bloom, swirl, stream, solidify

    var title: String {
        switch self {
        case .volley:   return "Launch volley"
        case .bloom:    return "Ink bloom"
        case .swirl:    return "Swirl"
        case .stream:   return "Stream"
        case .solidify: return "Solidify"
        }
    }

    /// Full refill duration; the display link runs until this much has elapsed.
    /// These are the shipping values from the handoff (section 8).
    var duration: CFTimeInterval {
        switch self {
        case .volley:   return 0.76   // 420 ms max delay + 340 ms travel
        case .bloom:    return 0.90
        case .swirl:    return 0.85
        case .stream:   return 1.00
        case .solidify: return 1.10
        }
    }
}

/// How the just-passed tick exits on each second. Persisted under
/// `"tickPassStyle"`; `none` keeps the original instant flip to track.
enum TickPassStyle: String, CaseIterable {
    case none, melt, fall, burst, sink

    var title: String {
        switch self {
        case .none:  return "None"
        case .melt:  return "Melt"
        case .fall:  return "Fall away"
        case .burst: return "Burst"
        case .sink:  return "Sink"
        }
    }

    /// Every tick-pass runs over this fixed window — short enough to complete
    /// well within the 1 s countdown cadence.
    static let duration: CFTimeInterval = 0.55
}

/// Single home for the two persisted style choices. `refillStyle` /
/// `tickPassStyle` are the raw user preferences (what the settings picker
/// shows); the `effective…` variants fold in the Reduce Motion overrides so no
/// view has to special-case accessibility.
enum DialAnimationSettings {

    static var refillStyle: RefillStyle {
        get {
            let raw = UserDefaults.standard.string(forKey: "refillStyle")
            return raw.flatMap(RefillStyle.init(rawValue:)) ?? .volley
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "refillStyle") }
    }

    static var tickPassStyle: TickPassStyle {
        get {
            let raw = UserDefaults.standard.string(forKey: "tickPassStyle")
            return raw.flatMap(TickPassStyle.init(rawValue:)) ?? .none
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "tickPassStyle") }
    }

    /// Reduce Motion pins the refill to Ink bloom — it grows every tick in
    /// place with no travel across the dial.
    static var effectiveRefillStyle: RefillStyle {
        UIAccessibility.isReduceMotionEnabled ? .bloom : refillStyle
    }

    /// Reduce Motion downgrades any travelling tick-pass to Melt (shrink in
    /// place, no translation) — but still honors an explicit `none`, so a user
    /// who wanted zero per-second motion keeps it.
    static var effectiveTickPassStyle: TickPassStyle {
        guard UIAccessibility.isReduceMotionEnabled else { return tickPassStyle }
        return tickPassStyle == .none ? .none : .melt
    }
}

// MARK: - Ring renderer

/// The shared drawing engine behind both `TickDialView` (single ring) and
/// `ConcentricDialView` (three rings). It owns every refill- and tick-pass
/// geometry so the look never diverges between styles; callers only pass the
/// current value, elapsed times, and their palette.
enum DialRing {

    // MARK: Shared math

    /// Stable per-index pseudo-random in [0,1): fract(sin(i·12.9898 + 1) · 43758.5453).
    static func hash(_ i: Int) -> CGFloat {
        let x = sin(CGFloat(i) * 12.9898 + 1) * 43758.5453
        return x - floor(x)
    }
    static func clamp(_ x: CGFloat) -> CGFloat { max(0, min(1, x)) }
    static func easeOutCubic(_ t: CGFloat) -> CGFloat { 1 - pow(1 - t, 3) }
    /// Slight overshoot past the slot, c1 = 1.70158.
    static func easeOutBack(_ t: CGFloat) -> CGFloat {
        let c1: CGFloat = 1.70158, c3 = c1 + 1
        return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
    }
    private static func rad(_ deg: CGFloat) -> CGFloat { deg * .pi / 180 }

    // MARK: Public draw

    /// Draws one ring: track underneath, the refill/settled filled ticks, and
    /// the exiting tick-pass mark. `refill` / `tickPass` are nil when idle.
    /// `dialSize` (the view's point size) scales the pt-based offsets so a small
    /// Ledger dial and a giant T-Minus dial exit proportionally.
    static func drawRing(cx: CGFloat, cy: CGFloat, inner: CGFloat, outer: CGFloat,
                         total: Int, selected: Int, dialSize: CGFloat,
                         refill: (style: RefillStyle, elapsed: CFTimeInterval)?,
                         tickPass: (style: TickPassStyle, index: Int, elapsed: CFTimeInterval)?,
                         trackColor: UIColor, filledColor: UIColor, accentColor: UIColor,
                         tickWidth: CGFloat, selectedTickWidth: CGFloat) {
        guard total > 0 else { return }
        let step = 2 * CGFloat.pi / CGFloat(total)
        let ptScale = dialSize / 200          // "20 pt at a 200 pt dial" → scales with size

        func mark(_ angle: CGFloat, _ r0: CGFloat, _ r1: CGFloat, _ color: UIColor, _ w: CGFloat) {
            let path = UIBezierPath()
            path.move(to: CGPoint(x: cx + cos(angle) * r0, y: cy + sin(angle) * r0))
            path.addLine(to: CGPoint(x: cx + cos(angle) * r1, y: cy + sin(angle) * r1))
            path.lineCapStyle = .round
            path.lineWidth = w
            color.setStroke()
            path.stroke()
        }
        func angleOf(_ i: Int) -> CGFloat { -CGFloat.pi / 2 + CGFloat(i) * step }

        // 1) Track underneath, always visible.
        for i in 0..<total { mark(angleOf(i), inner, outer, trackColor, tickWidth) }

        // 2) Solidify's solid band — the one refill underlay drawn beneath ticks.
        if let refill, refill.style == .solidify {
            let e = clamp(CGFloat(refill.elapsed / RefillStyle.solidify.duration))
            let r0 = inner
            let r1: CGFloat, alpha: CGFloat
            if e < 0.3 {
                r1 = inner + (outer - inner) * (e / 0.3); alpha = 0.9          // grow outward
            } else {
                r1 = outer; alpha = 0.9 * (1 - (e - 0.3) / 0.7)                // fade as ticks emerge
            }
            if alpha > 0.001, r1 > r0 {
                let bandPath = UIBezierPath(arcCenter: CGPoint(x: cx, y: cy), radius: (r0 + r1) / 2,
                                            startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                bandPath.lineWidth = r1 - r0
                accentColor.withAlphaComponent(alpha).setStroke()
                bandPath.stroke()
            }
        }

        // 3) Tick-pass: the just-vacated slot exits over 550 ms. The owning view
        //    suppresses this while a refill is running, so they never fight.
        if let tp = tickPass, tp.style != .none, tp.index >= 0, tp.index < total {
            let p = clamp(CGFloat(tp.elapsed / TickPassStyle.duration))
            if p < 1 {
                drawTickPass(tp.style, mark: mark, angle: angleOf(tp.index), index: tp.index,
                             inner: inner, outer: outer, p: p,
                             filled: filledColor, tickWidth: tickWidth, ptScale: ptScale)
            }
        }

        // 4) Filled ticks up to the current value.
        guard selected >= 0 else { return }
        for i in 0...selected {
            let angle = angleOf(i)
            if let refill {
                switch refillTick(refill.style, i: i, total: total, elapsed: refill.elapsed,
                                  inner: inner, outer: outer, accent: accentColor, tickWidth: tickWidth) {
                case .hidden:            continue
                case .flight(let d):     mark(d.angle, d.r0, d.r1, d.color, d.width); continue
                case .settled:           break     // fall through to the settled draw
                }
            }
            let settledColor = i == selected ? accentColor : filledColor
            let settledWidth = i == selected ? selectedTickWidth : tickWidth
            mark(angle, inner, outer, settledColor, settledWidth)
        }
    }

    // MARK: Refill geometry

    private struct TickDraw { let r0, r1, angle, width: CGFloat; let color: UIColor }
    private enum RefillTick { case hidden, settled; case flight(TickDraw) }

    /// State of one tick `i` at `elapsed` seconds into a refill of `style`.
    /// `hidden` = not launched yet; `settled` = has landed (caller draws the
    /// normal filled/accent tick); `flight` = mid-animation, draw as described.
    private static func refillTick(_ style: RefillStyle, i: Int, total: Int,
                                   elapsed: CFTimeInterval, inner: CGFloat, outer: CGFloat,
                                   accent: UIColor, tickWidth: CGFloat) -> RefillTick {
        let step = 2 * CGFloat.pi / CGFloat(total)
        let base = -CGFloat.pi / 2 + CGFloat(i) * step
        let e = CGFloat(elapsed / style.duration)          // overall progress 0…1

        switch style {
        case .volley:
            // Existing look: per-tick delay hash·420 ms, radial travel 340 ms.
            let t = CGFloat((elapsed - Double(hash(i)) * 0.42) / 0.34)
            if t <= 0 { return .hidden }
            if t >= 1 { return .settled }
            let s = easeOutBack(t)
            return .flight(TickDraw(r0: inner * s, r1: outer * s, angle: base,
                                    width: tickWidth + 0.5,
                                    color: accent.withAlphaComponent(0.3 + 0.7 * t)))

        case .bloom:
            // Each tick grows in place from its midpoint. Quietest option.
            let raw = (e - (CGFloat(i) / CGFloat(total)) * 0.7) / 0.3
            if raw <= 0 { return .hidden }
            if raw >= 1 { return .settled }
            let t = raw
            let mid = (inner + outer) / 2, half = (outer - inner) / 2 * t
            return .flight(TickDraw(r0: mid - half, r1: mid + half, angle: base,
                                    width: tickWidth,
                                    color: accent.withAlphaComponent(0.35 + 0.65 * t)))

        case .swirl:
            // Spirals out of the center, unwinding into the slot.
            let raw = (e - hash(i) * 0.4) / 0.45
            if raw <= 0 { return .hidden }
            if raw >= 1 { return .settled }
            let t = raw, s = easeOutCubic(t)
            return .flight(TickDraw(r0: inner * s, r1: outer * s,
                                    angle: base - rad(70) * (1 - s),
                                    width: tickWidth,
                                    color: accent.withAlphaComponent(0.3 + 0.7 * t)))

        case .stream:
            // Pours from 12 o'clock and slides around the ring, farthest first.
            let delay = (CGFloat(total - 1 - i) / CGFloat(total)) * 0.62
            let raw = (e - delay) / 0.38
            if raw <= 0 { return .hidden }
            if raw >= 1 { return .settled }
            let t = raw, s = 1 - pow(1 - t, 2.2)
            let angle = -CGFloat.pi / 2 + CGFloat(i) * step * s   // travels 12 o'clock → slot i
            return .flight(TickDraw(r0: inner, r1: outer, angle: angle,
                                    width: tickWidth,
                                    color: accent.withAlphaComponent(0.5 + 0.5 * t)))

        case .solidify:
            // Phase 1 (e < 0.3) hides ticks under the band (drawn in drawRing).
            // Phase 2 resolves the band into discrete ticks, staggered clockwise.
            if e < 0.3 { return .hidden }
            let t = (e - 0.3) / 0.7
            let lt = clamp((t - (CGFloat(i) / CGFloat(total)) * 0.55) / 0.45)
            if lt <= 0 { return .hidden }
            if lt >= 1 { return .settled }
            return .flight(TickDraw(r0: inner, r1: outer, angle: base,
                                    width: tickWidth,
                                    color: accent.withAlphaComponent(0.4 + 0.6 * lt)))
        }
    }

    // MARK: Tick-pass geometry

    /// Draws the exiting mark for the passed slot. `p` = 0…1 over 550 ms; the
    /// tick starts at the ring's filled color and fades to nothing.
    private static func drawTickPass(_ style: TickPassStyle,
                                     mark: (CGFloat, CGFloat, CGFloat, UIColor, CGFloat) -> Void,
                                     angle: CGFloat, index: Int, inner: CGFloat, outer: CGFloat,
                                     p: CGFloat, filled: UIColor, tickWidth: CGFloat, ptScale: CGFloat) {
        let fade = filled.withAlphaComponent(0.75 * (1 - p))
        switch style {
        case .none:
            break

        case .melt:
            // Shrinks toward its midpoint and dissolves.
            let mid = (inner + outer) / 2, half = (outer - inner) / 2 * (1 - p)
            mark(angle, mid - half, mid + half, fade, tickWidth)

        case .fall:
            // Slides outward off the ring and fades.
            let off = p * p * 20 * ptScale
            mark(angle, inner + off, outer + off, fade, tickWidth)

        case .sink:
            // Falls into the center, shrinking and curling slightly as it drops.
            let s = 1 - p * p
            let r0 = inner * s
            let r1 = (inner + (outer - inner) * max(0.15, 1 - p)) * s
            mark(angle + rad(10) * p, r0, r1, fade, tickWidth * (1 - 0.5 * p))

        case .burst:
            // Shatters into 5 fragments that scatter outward and dissolve.
            let mid = (inner + outer) / 2
            for f in 0..<5 {
                let r1h = hash(index * 7 + f)
                let r2h = hash(index * 13 + f + 3)
                let spread = rad((r1h - 0.5) * 26 * p)
                let center = mid + p * (14 + r2h * 22) * ptScale
                let len = (outer - inner) * (0.35 - 0.25 * p) * (0.5 + 0.5 * r2h)
                let w = tickWidth * (0.9 - 0.4 * p)
                mark(angle + spread, center - len / 2, center + len / 2,
                     filled.withAlphaComponent(0.8 * (1 - p)), w)
            }
        }
    }
}

// MARK: - Single-ring dial view

final class TickDialView: UIView {

    // MARK: - Configuration

    /// Number of ticks around the ring (24 for hours, 60 for minutes/seconds).
    var total: Int = 60 { didSet { setNeedsDisplay() } }

    var filledColor: UIColor = VisualStyle.ledgerFilled { didSet { setNeedsDisplay() } }
    var trackColor: UIColor = UIColor(white: 0.592, alpha: 0.14) { didSet { setNeedsDisplay() } }
    var accentColor: UIColor = UIColor(hex: 0xBFE8FB) { didSet { setNeedsDisplay() } }

    var tickWidth: CGFloat = 2.3 { didSet { setNeedsDisplay() } }
    var tickLengthRatio: CGFloat = 0.24 { didSet { setNeedsDisplay() } }

    /// How much of the view the ring uses.
    var ringScale: CGFloat = 0.95 { didSet { setNeedsDisplay() } }

    // MARK: - Value

    private(set) var value: Int = 0

    /// Sets the ring's value and picks the matching animation: a value that
    /// jumps up is a rollover → refill; a value that ticks down is a normal
    /// second passing → tick-pass on the vacated slot. A silent seed (style
    /// switch, date scrub) passes `animated: false` and just repaints.
    func setValue(_ newValue: Int, animated: Bool = true) {
        guard newValue != value else { return }
        let old = value
        value = newValue
        guard animated else { setNeedsDisplay(); return }
        if newValue > old {
            refill()                          // rollover (e.g. seconds 0 -> 59)
        } else {
            startTickPass(passing: old)       // the tick at the old slot exits
            setNeedsDisplay()
        }
    }

    private var clampedValue: Int { max(0, min(value, total - 1)) }

    // MARK: - Animation state

    private var refillStyle: RefillStyle = .volley
    private var refillStart: CFTimeInterval?
    private var passStyle: TickPassStyle = .none
    private var passIndex: Int = 0
    private var passStart: CFTimeInterval?
    private var link: CADisplayLink?

    // MARK: - Init

    override init(frame: CGRect) { super.init(frame: frame); commonInit() }
    required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapDial)))
    }

    deinit { link?.invalidate() }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil { link?.invalidate(); link = nil }   // don't animate off-screen
    }

    // MARK: - Public API

    /// Replay the refill in the currently selected style: every filled tick
    /// arrives fresh. Called automatically on rollover; call directly on appear
    /// or after a date change.
    func refill() {
        refillStyle = DialAnimationSettings.effectiveRefillStyle
        guard window != nil else { refillStart = nil; passStart = nil; setNeedsDisplay(); return }
        passStart = nil                       // a refill owns the ring; drop any exit
        refillStart = CACurrentMediaTime()
        ensureLink()
        setNeedsDisplay()
    }

    private func startTickPass(passing index: Int) {
        passStyle = DialAnimationSettings.effectiveTickPassStyle
        guard passStyle != .none, window != nil else { return }
        // Suppress while a refill still owns the ring (the refill window can
        // outlast the second that triggered it).
        if let start = refillStart, CACurrentMediaTime() - start < refillStyle.duration { return }
        passIndex = index
        passStart = CACurrentMediaTime()
        ensureLink()
    }

    @objc private func didTapDial() { refill() }   // a tap replays the current refill

    // MARK: - Display link

    private func ensureLink() {
        guard link == nil else { return }
        let l = CADisplayLink(target: self, selector: #selector(step))
        l.add(to: .main, forMode: .common)
        link = l
    }

    @objc private func step(_ link: CADisplayLink) {
        setNeedsDisplay()
        let now = CACurrentMediaTime()
        if let start = refillStart, now - start >= refillStyle.duration { refillStart = nil }
        if let start = passStart, now - start >= TickPassStyle.duration { passStart = nil }
        if refillStart == nil, passStart == nil { link.invalidate(); self.link = nil }
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard total > 0 else { return }

        let outer = (min(rect.width, rect.height) / 2 - tickWidth) * ringScale
        let inner = outer - outer * tickLengthRatio
        let now = CACurrentMediaTime()
        DialRing.drawRing(cx: rect.midX, cy: rect.midY, inner: inner, outer: outer,
                          total: total, selected: clampedValue, dialSize: min(rect.width, rect.height),
                          refill: refillStart.map { (refillStyle, now - $0) },
                          tickPass: passStart.map { (passStyle, passIndex, now - $0) },
                          trackColor: trackColor, filledColor: filledColor, accentColor: accentColor,
                          tickWidth: tickWidth, selectedTickWidth: tickWidth + 0.5)
    }
}
