//
//  TickDialView.swift
//  Countdown
//
//  A radial tick-mark dial drawn with Core Graphics instead of pre-rendered
//  PNGs. Ticks are laid out clockwise from the top; those behind the current
//  value are "filled", the single tick at the value is drawn in the accent
//  color, and the rest form a faint track. This replaces the hour0…23 and
//  minorsec0…59 image sets — the ring now scales to any size and can be
//  recolored or animated in code.
//

import UIKit

@IBDesignable
final class TickDialView: UIView {

    /// Number of ticks around the ring (24 for hours, 60 for minutes/seconds).
    @IBInspectable var total: Int = 60 {
        didSet { setNeedsDisplay() }
    }

    /// How many ticks are "spent". The tick at this index is the leading mark.
    @IBInspectable var value: Int = 0 {
        didSet { setNeedsDisplay() }
    }

    /// Ticks behind the leading edge.
    @IBInspectable var filledColor: UIColor = UIColor(white: 0.592, alpha: 0.95) {
        didSet { setNeedsDisplay() }
    }

    /// Ticks ahead of the leading edge.
    @IBInspectable var trackColor: UIColor = UIColor(white: 0.592, alpha: 0.15) {
        didSet { setNeedsDisplay() }
    }

    /// The single leading tick at `value`.
    @IBInspectable var accentColor: UIColor = UIColor(red: 0.749, green: 0.910, blue: 0.984, alpha: 1) {
        didSet { setNeedsDisplay() }
    }

    /// Stroke width of each tick.
    @IBInspectable var tickWidth: CGFloat = 2.6 {
        didSet { setNeedsDisplay() }
    }

    /// Tick length as a fraction of the dial radius.
    @IBInspectable var tickLengthRatio: CGFloat = 0.13 {
        didSet { setNeedsDisplay() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
    }

    override func draw(_ rect: CGRect) {
        guard total > 0 else { return }

        let center = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2 - tickWidth / 2
        let inner = outer - outer * tickLengthRatio
        let clamped = max(0, min(value, total))
        let step = (2 * CGFloat.pi) / CGFloat(total)

        for i in 0..<total {
            let angle = -CGFloat.pi / 2 + CGFloat(i) * step
            let start = CGPoint(x: center.x + cos(angle) * inner,
                                y: center.y + sin(angle) * inner)
            let end = CGPoint(x: center.x + cos(angle) * outer,
                              y: center.y + sin(angle) * outer)

            let path = UIBezierPath()
            path.move(to: start)
            path.addLine(to: end)
            path.lineCapStyle = .round

            if i == clamped {
                accentColor.setStroke()
                path.lineWidth = tickWidth + 0.4
            } else if i < clamped {
                filledColor.setStroke()
                path.lineWidth = tickWidth
            } else {
                trackColor.setStroke()
                path.lineWidth = tickWidth
            }
            path.stroke()
        }
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        setNeedsDisplay()
    }
}
