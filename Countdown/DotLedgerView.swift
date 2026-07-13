//
//  DotLedgerView.swift
//  Countdown
//
//  "One dot per day": a fixed grid holding every day of the countdown's span,
//  16 columns. Whole remaining days are solid accent discs; the day currently
//  in progress is highlighted as a gauge ring whose accent arc depletes with the
//  fraction of today left; elapsed days are faint hollow rings. As a day fully
//  drains the highlight steps to the next dot (a Dissolve cross-fade) and the
//  emptied day settles into a hollow ring.
//
//  Layer-backed: each cell owns three CAShapeLayers (disc / track / gauge) whose
//  opacities cross-fade between the three states, so a single dot animates its
//  role change independently and the gauge sweeps every second.
//

import UIKit

final class DotLedgerView: UIView {

    var accentColor: UIColor = UIColor(hex: 0xBFE8FB) { didSet { applyColors() } }
    var strokeColor: UIColor = UIColor(white: 1, alpha: 0.28) { didSet { applyColors() } }

    private let columns = 16
    private let maxRows = 9                      // caps the grid height (9 × 16 = 144-day capacity)
    private let cell: CGFloat = 19               // vertical pitch (row height)
    private let dotRadiusRatio: CGFloat = 0.22
    private let strokeWidth: CGFloat = 1.1
    private let gaugeWidth: CGFloat = 1.8        // the accent arc reads a touch bolder than the faint track
    private let dissolveDuration = 0.5

    /// Three marks per grid cell. Their opacities express the state:
    ///   solid day → disc; current day → track + gauge; elapsed day → track.
    private struct Dot {
        let disc: CAShapeLayer     // filled accent disc  (a whole day remaining)
        let track: CAShapeLayer    // faint full ring     (current day's day-track / an elapsed day)
        let gauge: CAShapeLayer    // accent arc          (fraction of the current day left)
    }
    private var dots: [Dot] = []
    private var overflowMarker: CAShapeLayer?     // accent ellipsis when more days remain than the grid can hold

    private var total = 0                         // days in the whole span (grid size)
    private var wholeDays = 0                     // fully-remaining days → solid discs
    private var dayFraction: CGFloat = 0          // fraction of the current day still left (1…0)

    private var capacity: Int { maxRows * columns }
    private var visibleCount: Int { min(max(total, 1), capacity) }
    private var currentIndex: Int { wholeDays }   // the highlighted "today" dot sits just past the solid days

    override init(frame: CGRect) { super.init(frame: frame); commonInit() }
    required init?(coder: NSCoder) { super.init(coder: coder); commonInit() }

    private func commonInit() {
        backgroundColor = .clear
        isOpaque = false
    }

    /// Seeds or advances the grid. `total` sizes it, `wholeDays` is the solid
    /// count, `dayFraction` fills the current dot's gauge. Only dots whose role
    /// changes animate; the per-second gauge sweep is silent.
    func setValues(total: Int, wholeDays: Int, dayFraction: CGFloat, animated: Bool) {
        let newTotal = max(total, 1)
        let newWhole = min(max(wholeDays, 0), newTotal)
        let totalChanged = newTotal != self.total
        self.total = newTotal
        self.wholeDays = newWhole
        self.dayFraction = min(max(dayFraction, 0), 1)

        if totalChanged {
            invalidateIntrinsicContentSize()
            rebuildLayers()
            applyStates(animated: false)         // fresh layers seed instantly
        } else {
            applyStates(animated: animated)
        }
    }

    override var intrinsicContentSize: CGSize {
        let neededRows = Int(ceil(Double(max(total, 1)) / Double(columns)))
        let rows = max(1, min(neededRows, maxRows))
        return CGSize(width: CGFloat(columns) * cell, height: CGFloat(rows) * cell)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutDots()
    }

    // MARK: - Layer lifecycle

    private func rebuildLayers() {
        dots.forEach { $0.disc.removeFromSuperlayer(); $0.track.removeFromSuperlayer(); $0.gauge.removeFromSuperlayer() }
        dots.removeAll()
        overflowMarker?.removeFromSuperlayer()
        overflowMarker = nil

        for _ in 0..<visibleCount {
            let track = CAShapeLayer()
            track.fillColor = UIColor.clear.cgColor
            track.strokeColor = strokeColor.cgColor
            track.lineWidth = strokeWidth

            let gauge = CAShapeLayer()
            gauge.fillColor = UIColor.clear.cgColor
            gauge.strokeColor = accentColor.cgColor
            gauge.lineWidth = gaugeWidth
            gauge.lineCap = .round
            gauge.strokeStart = 0

            let disc = CAShapeLayer()
            disc.fillColor = accentColor.cgColor

            layer.addSublayer(track)             // faint track underneath
            layer.addSublayer(gauge)             // accent arc over the track
            layer.addSublayer(disc)              // solid disc on top when it's a whole day
            dots.append(Dot(disc: disc, track: track, gauge: gauge))
        }

        let marker = CAShapeLayer()
        marker.fillColor = accentColor.cgColor
        marker.opacity = 0
        layer.addSublayer(marker)
        overflowMarker = marker

        layoutDots()
    }

    /// Each dot is its own cell-sized layer centered on its grid slot. The gauge
    /// path is a full circle starting at 12 o'clock going clockwise, so
    /// `strokeEnd = fraction` draws the remaining slice like a depleting clock.
    private func layoutDots() {
        guard !dots.isEmpty, bounds.width > 0 else { return }

        let colPitch = bounds.width / CGFloat(columns)   // fill the pinned width evenly
        let r = dotRadiusRatio * cell
        let ringR = r - strokeWidth / 2
        let side = cell
        let mid = CGPoint(x: side / 2, y: side / 2)

        let discPath = UIBezierPath(arcCenter: mid, radius: r,
                                    startAngle: 0, endAngle: 2 * .pi, clockwise: true).cgPath
        let ringPath = UIBezierPath(arcCenter: mid, radius: ringR,
                                    startAngle: 0, endAngle: 2 * .pi, clockwise: true).cgPath
        let gaugePath = UIBezierPath(arcCenter: mid, radius: ringR,
                                     startAngle: -.pi / 2, endAngle: -.pi / 2 + 2 * .pi,
                                     clockwise: true).cgPath

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (i, dot) in dots.enumerated() {
            let cx = colPitch * (CGFloat(i % columns) + 0.5)
            let cy = cell * (CGFloat(i / columns) + 0.5)
            let frame = CGRect(x: cx - side / 2, y: cy - side / 2, width: side, height: side)
            dot.disc.frame = frame;  dot.disc.path = discPath
            dot.track.frame = frame; dot.track.path = ringPath
            dot.gauge.frame = frame; dot.gauge.path = gaugePath
        }

        if let marker = overflowMarker, visibleCount > 0 {
            let i = visibleCount - 1                       // marker lives in the last cell
            let cx = colPitch * (CGFloat(i % columns) + 0.5)
            let cy = cell * (CGFloat(i / columns) + 0.5)
            marker.frame = CGRect(x: cx - side / 2, y: cy - side / 2, width: side, height: side)
            let dotR: CGFloat = 1.3, gap: CGFloat = 3.6    // "…more beyond" ellipsis
            let ellipsis = UIBezierPath()
            for k in -1...1 {
                ellipsis.append(UIBezierPath(arcCenter: CGPoint(x: mid.x + CGFloat(k) * gap, y: mid.y),
                                             radius: dotR, startAngle: 0, endAngle: 2 * .pi, clockwise: true))
            }
            marker.path = ellipsis.cgPath
        }
        CATransaction.commit()
    }

    // MARK: - State

    private enum Role { case solid, current, elapsed }

    private func role(of index: Int) -> Role {
        if index < wholeDays { return .solid }
        if index == currentIndex && dayFraction > 0.0001 { return .current }
        return .elapsed
    }

    private func applyStates(animated: Bool) {
        // Overflow: more remaining days than the grid can show → fill all but the
        // last cell with solid discs and mark the last as "…more beyond". Gated on
        // the (shrinking) remaining count, so it clears when the countdown enters
        // the final window and precise draining begins.
        let overflow = visibleCount > 0 && wholeDays >= visibleCount
        let markerIndex = visibleCount - 1

        for (i, dot) in dots.enumerated() {
            let discTarget: Float, trackTarget: Float, gaugeTarget: Float
            if overflow {
                discTarget = i < markerIndex ? 1 : 0     // last cell hosts the marker instead of a disc
                trackTarget = 0
                gaugeTarget = 0
            } else {
                switch role(of: i) {
                case .solid:   discTarget = 1; trackTarget = 0; gaugeTarget = 0
                case .current: discTarget = 0; trackTarget = 1; gaugeTarget = 1
                case .elapsed: discTarget = 0; trackTarget = 1; gaugeTarget = 0
                }
            }

            // The gauge sweep itself is silent every second; only role changes fade.
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            dot.gauge.strokeEnd = gaugeTarget == 1 ? dayFraction : 0
            CATransaction.commit()

            let changed = dot.disc.opacity != discTarget
                || dot.track.opacity != trackTarget
                || dot.gauge.opacity != gaugeTarget
            if animated && changed {
                let discWasSolid = dot.disc.opacity == 1
                fade(dot.disc, to: discTarget)
                fade(dot.track, to: trackTarget)
                fade(dot.gauge, to: gaugeTarget)
                // Scale flourish as a solid day dissolves into the gauge ring.
                if discTarget == 0 && discWasSolid {
                    let scale = CABasicAnimation(keyPath: "transform.scale")
                    scale.fromValue = 1.0
                    scale.toValue = 0.6
                    scale.duration = dissolveDuration
                    scale.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                    dot.disc.add(scale, forKey: "dissolveScale")
                }
            } else {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                dot.disc.opacity = discTarget
                dot.track.opacity = trackTarget
                dot.gauge.opacity = gaugeTarget
                CATransaction.commit()
            }
        }

        if let marker = overflowMarker {
            let target: Float = overflow ? 1 : 0
            if animated && marker.opacity != target {
                fade(marker, to: target)
            } else {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                marker.opacity = target
                CATransaction.commit()
            }
        }
    }

    private func fade(_ layer: CAShapeLayer, to target: Float) {
        guard layer.opacity != target else { return }
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = layer.presentation()?.opacity ?? layer.opacity
        fade.toValue = target
        fade.duration = dissolveDuration
        fade.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        layer.opacity = target                    // commit the model value
        layer.add(fade, forKey: "dissolveFade")
    }

    private func applyColors() {
        for dot in dots {
            dot.disc.fillColor = accentColor.cgColor
            dot.gauge.strokeColor = accentColor.cgColor
            dot.track.strokeColor = strokeColor.cgColor
        }
        overflowMarker?.fillColor = accentColor.cgColor
    }
}
