//
//  ConcentricDialView.swift
//  Countdown
//
//  Three nested tick rings in one dial, outer→inner = seconds (60),
//  minutes (60), hours (24). Used at 252 pt in Editorial and at 620 pt
//  (cropped off the right screen edge) in T-Minus. Each ring refills in the
//  selected refill style when its unit rolls over (an hour rollover refills
//  minutes and seconds simultaneously), and plays the selected tick-pass style
//  when its unit ticks down. All geometry lives in the shared `DialRing`.
//

import UIKit
import QuartzCore

final class ConcentricDialView: UIView {

    // MARK: - Configuration

    /// Ring tick counts, outer→inner: seconds, minutes, hours.
    private let totals = [60, 60, 24]

    /// Filled-tick color per ring, outer→inner.
    var ringFilledColors: [UIColor] = [UIColor(white: 1, alpha: 0.3),
                                       UIColor(white: 1, alpha: 0.22),
                                       UIColor(white: 1, alpha: 0.14)] { didSet { setNeedsDisplay() } }
    var trackColor: UIColor = UIColor(white: 1, alpha: 0.05) { didSet { setNeedsDisplay() } }
    var accentColor: UIColor = UIColor(hex: 0xFF7A59) { didSet { setNeedsDisplay() } }

    var tickWidth: CGFloat = 1.9 { didSet { setNeedsDisplay() } }
    var selectedTickWidth: CGFloat = 2.5 { didSet { setNeedsDisplay() } }

    // Concentric geometry as fractions of the dial size (design tokens).
    private let bandRatio: CGFloat = 0.08
    private let gapRatio: CGFloat = 0.032
    private let outerRadiusRatio: CGFloat = 0.475

    // MARK: - Values

    /// Current values per ring, outer→inner: seconds, minutes, hours.
    private(set) var values = [0, 0, 0]

    // Per-ring animation state. Each ring captures its style at trigger time so
    // the display-link cleanup below uses the right duration even if rings
    // start at different moments or settings change mid-flight.
    private var refillStyles: [RefillStyle] = [.volley, .volley, .volley]
    private var refillStarts: [CFTimeInterval?] = [nil, nil, nil]
    private var passStyles: [TickPassStyle] = [.none, .none, .none]
    private var passIndices = [0, 0, 0]
    private var passStarts: [CFTimeInterval?] = [nil, nil, nil]
    private var link: CADisplayLink?

    /// Updates all three rings: a ring whose value jumped up (rolled over)
    /// refills; a ring whose value ticked down plays its tick-pass on the
    /// vacated slot. An hour rollover therefore refills minutes AND seconds in
    /// the same frame.
    func setValues(seconds: Int, minutes: Int, hours: Int, animated: Bool = true) {
        let new = [seconds, minutes, hours]
        guard new != values else { return }
        let old = values
        values = new
        if animated {
            for k in 0..<3 {
                if new[k] > old[k] { startRefill(ring: k) }
                else if new[k] < old[k] { startTickPass(ring: k, passing: old[k]) }
            }
        }
        setNeedsDisplay()
    }

    /// Refill every ring (on appear / date change) in the selected style.
    func refillAll() {
        for k in 0..<3 { startRefill(ring: k) }
        setNeedsDisplay()
    }

    private func startRefill(ring k: Int) {
        refillStyles[k] = DialAnimationSettings.effectiveRefillStyle
        guard window != nil else { refillStarts[k] = nil; passStarts[k] = nil; return }
        passStarts[k] = nil                   // a refill owns the ring; drop any exit
        refillStarts[k] = CACurrentMediaTime()
        ensureLink()
    }

    private func startTickPass(ring k: Int, passing index: Int) {
        passStyles[k] = DialAnimationSettings.effectiveTickPassStyle
        guard passStyles[k] != .none, window != nil else { return }
        // Suppress while this ring's refill window is still running.
        if let start = refillStarts[k], CACurrentMediaTime() - start < refillStyles[k].duration { return }
        passIndices[k] = index
        passStarts[k] = CACurrentMediaTime()
        ensureLink()
    }

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
        if newWindow == nil { link?.invalidate(); link = nil }
    }

    /// A concentric dial treats all three rings as one control, so a tap
    /// replays every ring's refill together.
    @objc private func didTapDial() { refillAll() }

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
        for k in 0..<3 {
            if let start = refillStarts[k], now - start >= refillStyles[k].duration { refillStarts[k] = nil }
            if let start = passStarts[k], now - start >= TickPassStyle.duration { passStarts[k] = nil }
        }
        let active = refillStarts.contains { $0 != nil } || passStarts.contains { $0 != nil }
        if !active { link.invalidate(); self.link = nil }
    }

    // MARK: - Drawing

    override func draw(_ rect: CGRect) {
        let size = min(rect.width, rect.height)
        let band = bandRatio * size
        let gap = gapRatio * size
        let now = CACurrentMediaTime()

        for k in 0..<3 {
            let outer = outerRadiusRatio * size - CGFloat(k) * (band + gap)
            let inner = outer - band
            let total = totals[k]
            let filled = ringFilledColors[min(k, ringFilledColors.count - 1)]
            DialRing.drawRing(cx: rect.midX, cy: rect.midY, inner: inner, outer: outer,
                              total: total, selected: max(0, min(values[k], total - 1)), dialSize: size,
                              refill: refillStarts[k].map { (refillStyles[k], now - $0) },
                              tickPass: passStarts[k].map { (passStyles[k], passIndices[k], now - $0) },
                              trackColor: trackColor, filledColor: filled, accentColor: accentColor,
                              tickWidth: tickWidth, selectedTickWidth: selectedTickWidth)
        }
    }
}
