//
//  TickDialView.swift
//  Countdown
//
//  A single-ring radial tick dial drawn with Core Graphics. Ticks fill
//  clockwise from the top up to the current value; the tick at the value is
//  the accent mark. Whenever the ring refills — on appear, on rollover
//  (value jumps up, e.g. seconds 0 -> 59) or on a date change — the filled
//  ticks arrive as a "launch volley": each tick scales radially out from the
//  dial center to its slot on its own pseudo-random delay.
//

import UIKit
import QuartzCore

/// Shared launch-volley math (also used by ConcentricDialView).
enum Volley {
    /// Per-tick delay spread: `hash(i) × 420 ms`.
    static let maxDelay: CFTimeInterval = 0.42
    /// Per-tick radial travel time.
    static let travel: CFTimeInterval = 0.34
    /// Full refill duration (last tick launched + landed).
    static let total: CFTimeInterval = maxDelay + travel

    /// Stable per-index pseudo-random in [0,1): fract(sin(i·12.9898 + 1) · 43758.5453).
    static func hash(_ i: Int) -> CGFloat {
        let x = sin(CGFloat(i) * 12.9898 + 1) * 43758.5453
        return x - floor(x)
    }

    /// Slight overshoot past the slot, c1 = 1.70158.
    static func easeOutBack(_ t: CGFloat) -> CGFloat {
        let c1: CGFloat = 1.70158, c3 = c1 + 1
        return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)
    }

    /// Normalized progress for tick `i` at `elapsed` seconds into a volley.
    /// < 0 = not yet launched, 0…1 = traveling, ≥ 1 = landed.
    static func progress(_ i: Int, elapsed: CFTimeInterval) -> CGFloat {
        CGFloat((elapsed - Double(hash(i)) * maxDelay) / travel)
    }

    /// Draws one ring of radial ticks: the track underneath, then the filled
    /// ticks up to `selected`, each either settled or mid-volley when
    /// `elapsed` is non-nil. Shared by TickDialView (single ring) and
    /// ConcentricDialView (three rings) so the volley look never diverges.
    static func drawRing(cx: CGFloat, cy: CGFloat, inner: CGFloat, outer: CGFloat,
                         total: Int, selected: Int, elapsed: CFTimeInterval?,
                         trackColor: UIColor, filledColor: UIColor, accentColor: UIColor,
                         tickWidth: CGFloat, selectedTickWidth: CGFloat) {
        guard total > 0 else { return }
        let stepAngle = 2 * CGFloat.pi / CGFloat(total)

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
            let angle = -CGFloat.pi / 2 + CGFloat(i) * stepAngle

            // Track ticks stay visible underneath throughout.
            mark(angle, inner, outer, trackColor, tickWidth)

            guard i <= selected else { continue }
            let settledColor = i == selected ? accentColor : filledColor
            let settledWidth = i == selected ? selectedTickWidth : tickWidth

            if let elapsed {
                let t = progress(i, elapsed: elapsed)
                if t <= 0 { continue }                          // not yet launched
                if t < 1 {
                    let s = easeOutBack(t)
                    mark(angle, inner * s, outer * s,
                         accentColor.withAlphaComponent(0.3 + 0.7 * t), tickWidth + 0.5)
                    continue
                }
            }
            mark(angle, inner, outer, settledColor, settledWidth)
        }
    }
}

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

    /// Sets the ring's value. A rollover (value jumps up) replays the launch
    /// volley — but only when `animated` is true, so a silent rebuild (style
    /// switch, date scrub) can seed the value without triggering the sweep.
    func setValue(_ newValue: Int, animated: Bool = true) {
        guard newValue != value else { return }
        let increased = newValue > value
        value = newValue
        if animated && increased {
            refill()               // rollover (e.g. seconds 0 -> 59)
        } else {
            setNeedsDisplay()      // normal countdown tick, or silent seed
        }
    }

    private var clampedValue: Int { max(0, min(value, total - 1)) }

    // MARK: - Volley state

    private var volleyStart: CFTimeInterval?
    private var link: CADisplayLink?

    // MARK: - Init

    override init(frame: CGRect) { super.init(frame: frame); commonInit() }
    required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }

    deinit { link?.invalidate() }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil { link?.invalidate(); link = nil }   // don't animate off-screen
    }

    // MARK: - Public API

    /// Replay the launch volley: every filled tick flies out from the center
    /// to its slot on its own delay. Called automatically on rollover; call
    /// directly on appear or after a date change.
    func refill() {
        guard window != nil else { volleyStart = nil; setNeedsDisplay(); return }
        volleyStart = CACurrentMediaTime()
        ensureLink()
        setNeedsDisplay()
    }

    // MARK: - Display link

    private func ensureLink() {
        guard link == nil else { return }
        let l = CADisplayLink(target: self, selector: #selector(step))
        l.add(to: .main, forMode: .common)
        link = l
    }

    @objc private func step(_ link: CADisplayLink) {
        setNeedsDisplay()
        if let start = volleyStart, CACurrentMediaTime() - start >= Volley.total {
            volleyStart = nil
        }
        if volleyStart == nil { link.invalidate(); self.link = nil }
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        guard total > 0 else { return }

        let outer = (min(rect.width, rect.height) / 2 - tickWidth) * ringScale
        let inner = outer - outer * tickLengthRatio
        Volley.drawRing(cx: rect.midX, cy: rect.midY, inner: inner, outer: outer,
                        total: total, selected: clampedValue,
                        elapsed: volleyStart.map { CACurrentMediaTime() - $0 },
                        trackColor: trackColor, filledColor: filledColor, accentColor: accentColor,
                        tickWidth: tickWidth, selectedTickWidth: tickWidth + 0.5)
    }
}
