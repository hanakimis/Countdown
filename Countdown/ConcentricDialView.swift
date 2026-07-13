//
//  ConcentricDialView.swift
//  Countdown
//
//  Three nested tick rings in one dial, outer→inner = seconds (60),
//  minutes (60), hours (24). Used at 252 pt in Editorial and at 620 pt
//  (cropped off the right screen edge) in T-Minus. Each ring refills with
//  the shared launch volley when its unit rolls over; an hour rollover
//  refills minutes and seconds simultaneously.
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
    private var volleyStarts: [CFTimeInterval?] = [nil, nil, nil]
    private var link: CADisplayLink?

    /// Updates all three rings; any ring whose value jumped up (rolled over)
    /// starts its volley. Hour rollover therefore refills minutes AND
    /// seconds in the same frame.
    func setValues(seconds: Int, minutes: Int, hours: Int, animated: Bool = true) {
        let new = [seconds, minutes, hours]
        guard new != values else { return }
        if animated {
            for k in 0..<3 where new[k] > values[k] {
                volleyStarts[k] = window != nil ? CACurrentMediaTime() : nil
            }
        }
        values = new
        if volleyStarts.contains(where: { $0 != nil }) { ensureLink() }
        setNeedsDisplay()
    }

    /// Volley-refill every ring (on appear / date change).
    func refillAll() {
        guard window != nil else { volleyStarts = [nil, nil, nil]; setNeedsDisplay(); return }
        let now = CACurrentMediaTime()
        volleyStarts = [now, now, now]
        ensureLink()
        setNeedsDisplay()
    }

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
        if newWindow == nil { link?.invalidate(); link = nil }
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
        let now = CACurrentMediaTime()
        for k in 0..<3 {
            if let start = volleyStarts[k], now - start >= Volley.total { volleyStarts[k] = nil }
        }
        if !volleyStarts.contains(where: { $0 != nil }) { link.invalidate(); self.link = nil }
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
            Volley.drawRing(cx: rect.midX, cy: rect.midY, inner: inner, outer: outer,
                            total: total, selected: max(0, min(values[k], total - 1)),
                            elapsed: volleyStarts[k].map { now - $0 },
                            trackColor: trackColor, filledColor: filled, accentColor: accentColor,
                            tickWidth: tickWidth, selectedTickWidth: selectedTickWidth)
        }
    }
}
