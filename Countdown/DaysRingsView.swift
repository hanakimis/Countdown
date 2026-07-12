//
//  DaysRingsView.swift
//  Countdown
//
//  The days-left column: one small "medallion" of three concentric rings per
//  day, echoing the hour/minute/second dials. The first medallion (the current
//  day) is drawn live — its three rings fill as arcs from the current hours,
//  minutes and seconds, so it reads as a tiny working clock; the days ahead are
//  plain rings.
//

import UIKit

@IBDesignable
final class DaysRingsView: UIView {

    /// Total days remaining (number of medallions).
    @IBInspectable var days: Int = 0 { didSet { setNeedsDisplay() } }

    // Live components for the current-day medallion.
    private var hours = 0
    private var minutes = 0
    private var seconds = 0

    @IBInspectable var ringColor: UIColor = UIColor(white: 0.70, alpha: 0.82) { didSet { setNeedsDisplay() } }
    @IBInspectable var accentColor: UIColor = UIColor(red: 0.749, green: 0.910, blue: 0.984, alpha: 1) { didSet { setNeedsDisplay() } }
    @IBInspectable var faintColor: UIColor = UIColor(white: 0.592, alpha: 0.13) { didSet { setNeedsDisplay() } }

    /// Space at the top reserved for the "N Days Left" label above the grid.
    @IBInspectable var topInset: CGFloat = 46 { didSet { setNeedsDisplay() } }

    func update(days: Int, hours: Int, minutes: Int, seconds: Int) {
        self.hours = max(0, hours)
        self.minutes = max(0, minutes)
        self.seconds = max(0, seconds)
        self.days = days                 // triggers redraw via didSet
    }

    override init(frame: CGRect) { super.init(frame: frame); commonInit() }
    required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }

    override func draw(_ rect: CGRect) {
        let n = max(0, days)
        guard n > 0 else { return }

        let cols = n <= 24 ? 5 : (n <= 90 ? 6 : 7)
        let rows = max(1, Int(ceil(Double(n) / Double(cols))))
        let availW = rect.width
        let availH = max(1, rect.height - topInset)
        let cell = min(availW / CGFloat(cols), availH / CGFloat(rows), 30)
        let R = cell * 0.34
        let lineW = max(0.5, R * 0.075)
        let ox = (availW - CGFloat(cols) * cell) / 2 + cell / 2

        for i in 0..<n {
            let c = i % cols, rw = i / cols
            let cx = ox + CGFloat(c) * cell
            let cy = topInset + cell / 2 + CGFloat(rw) * cell

            if i == 0 {
                // current day — live arcs, like the big dials
                arcRing(cx, cy, R,        CGFloat(seconds) / 60, lineW)
                arcRing(cx, cy, R * 0.64, CGFloat(minutes) / 60, lineW)
                arcRing(cx, cy, R * 0.30, CGFloat(hours) / 24,   lineW)
            } else {
                ringColor.setStroke()
                ring(cx, cy, R, lineW)
                ring(cx, cy, R * 0.64, lineW)
                ring(cx, cy, R * 0.30, lineW)
            }
        }
    }

    private func ring(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ w: CGFloat) {
        let p = UIBezierPath(arcCenter: CGPoint(x: cx, y: cy), radius: r,
                             startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        p.lineWidth = w
        p.stroke()
    }

    private func arcRing(_ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat, _ frac: CGFloat, _ w: CGFloat) {
        let center = CGPoint(x: cx, y: cy)
        faintColor.setStroke()
        let bg = UIBezierPath(arcCenter: center, radius: r, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        bg.lineWidth = w
        bg.stroke()

        accentColor.setStroke()
        let end = -CGFloat.pi / 2 + max(0.001, min(1, frac)) * 2 * .pi
        let fg = UIBezierPath(arcCenter: center, radius: r, startAngle: -.pi / 2, endAngle: end, clockwise: true)
        fg.lineWidth = w
        fg.lineCapStyle = .round
        fg.stroke()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        if days == 0 { days = 37 }       // preview content in IB
    }
}
