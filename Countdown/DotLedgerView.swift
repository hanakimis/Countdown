//
//  DotLedgerView.swift
//  Countdown
//
//  "One dot per day": a grid with one dot per remaining day, 16 columns.
//  Day 0 (today) is a filled accent dot; the rest are stroked circles.
//  Replaces the old DaysRingsView medallion grid in the redesigned styles.
//

import UIKit

final class DotLedgerView: UIView {

    var days: Int = 0 {
        didSet {
            guard days != oldValue else { return }
            invalidateIntrinsicContentSize()
            setNeedsDisplay()
        }
    }

    var accentColor: UIColor = UIColor(hex: 0xBFE8FB) { didSet { setNeedsDisplay() } }
    var strokeColor: UIColor = UIColor(white: 1, alpha: 0.28) { didSet { setNeedsDisplay() } }

    private let columns = 16
    private let maxRows = 6                     // caps the grid height; longer counts show an overflow marker
    private let cell: CGFloat = 19
    private let dotRadiusRatio: CGFloat = 0.22
    private let strokeWidth: CGFloat = 1.1

    /// Dots that fit before the grid is capped (the last one becomes the
    /// "more beyond" marker when the countdown exceeds this).
    private var capacity: Int { maxRows * columns }

    override init(frame: CGRect) { super.init(frame: frame); commonInit() }
    required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }

    override var intrinsicContentSize: CGSize {
        let neededRows = Int(ceil(Double(max(days, 1)) / Double(columns)))
        let rows = max(1, min(neededRows, maxRows))     // never taller than the cap
        return CGSize(width: CGFloat(columns) * cell, height: CGFloat(rows) * cell)
    }

    override func draw(_ rect: CGRect) {
        let n = max(days, 1)                       // today is always a dot
        let overflow = n > capacity                // more days than the grid can hold
        let visible = overflow ? capacity : n
        let r = dotRadiusRatio * cell

        for i in 0..<visible {
            let cx = CGFloat(i % columns) * cell + cell / 2
            let cy = CGFloat(i / columns) * cell + cell / 2

            if overflow && i == visible - 1 {
                // Terminal cell: an accent ellipsis meaning "…more beyond".
                accentColor.setFill()
                for k in -1...1 {
                    let d = UIBezierPath(arcCenter: CGPoint(x: cx + CGFloat(k) * 3.4, y: cy), radius: 1.2,
                                         startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                    d.fill()
                }
            } else if i == 0 {
                let dot = UIBezierPath(arcCenter: CGPoint(x: cx, y: cy), radius: r,
                                       startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                accentColor.setFill()
                dot.fill()
            } else {
                let dot = UIBezierPath(arcCenter: CGPoint(x: cx, y: cy), radius: r - strokeWidth / 2,
                                       startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                dot.lineWidth = strokeWidth
                strokeColor.setStroke()
                dot.stroke()
            }
        }
    }
}
