//
//  DuoViews.swift
//  Countdown
//
//  Small views and types used only by the foldable layouts (the unfolded
//  spread and the half-open table-top clock on iPhone Duo).
//

import UIKit

/// The arrangement on screen. Chosen from the scene size and the hinge, not
/// from the device model, so any wide scene gets the spread.
enum CountdownLayout: Equatable {
    /// The phone layout. `short` is the Duo's outer display (678 pt tall),
    /// where the Ledger unit rows tighten so they clear the days numeral.
    case compact(short: Bool)
    /// Unfolded, hinge vertical: two panels side by side.
    case spread
    /// Half-open on a desk, hinge horizontal: a clock face above, touch below.
    case tabletop

    var isShort: Bool { if case .compact(let short) = self { return short } else { return false } }
    var isCompact: Bool { if case .compact = self { return true } else { return false } }
}

/// Views only the spread / table-top builders create. `refreshDuo` fills in
/// whichever ones exist, so each builder registers just what it made.
struct DuoRefs {
    /// The in-content gear (header), when the system bar isn't hosting it.
    weak var headerGear: UIButton?
    weak var todayGauge: TodayGaugeView?
    weak var todayCaption: UILabel?
    weak var spanCaption: UILabel?
    weak var legendTodayLabel: UILabel?
    weak var sinceLabel: UILabel?
    weak var monthIndex: MonthIndexView?
    /// Table-top only: today's date on the clock face, and the target pill.
    weak var clockDateLabel: UILabel?
    weak var pillLabel: UILabel?
    /// Table-top appends "· day N of M" to the since line.
    var sinceIncludesDay = false
    /// Editorial's summary column: started / spent / left.
    var metaValueLabels: [UILabel] = []
}

// MARK: - Today gauge

/// The ledger's "today" dot drawn large: a faint track ring and an accent arc
/// for the share of today still left. The hero repeats this glyph so the one
/// day it singles out is visibly the same day as the gauge in the grid.
final class TodayGaugeView: UIView {
    var fraction: CGFloat = 0 { didSet { if fraction != oldValue { setNeedsDisplay() } } }
    var accentColor: UIColor = .white { didSet { setNeedsDisplay() } }
    var trackColor: UIColor = UIColor(white: 1, alpha: 0.28) { didSet { setNeedsDisplay() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        let side = min(bounds.width, bounds.height)
        guard side > 0 else { return }
        // Same proportions as the ledger dot (gauge 1.8 on a ~4.2 pt radius).
        let gauge = max(1.8, side * 0.11)
        let r = side / 2 - gauge / 2
        let c = CGPoint(x: bounds.midX, y: bounds.midY)

        let track = UIBezierPath(arcCenter: c, radius: r, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
        track.lineWidth = gauge * 0.6
        trackColor.setStroke()
        track.stroke()

        guard fraction > 0.0001 else { return }
        let start = -CGFloat.pi / 2
        let arc = UIBezierPath(arcCenter: c, radius: r, startAngle: start,
                               endAngle: start + 2 * .pi * min(fraction, 1), clockwise: true)
        arc.lineWidth = gauge
        arc.lineCapStyle = .round
        accentColor.setStroke()
        arc.stroke()
    }
}

// MARK: - Legend glyph

/// One of the ledger's three dot kinds, drawn at legend size.
final class LedgerGlyphView: UIView {
    enum Kind { case elapsed, remaining }
    private let kind: Kind
    private let color: UIColor

    init(kind: Kind, color: UIColor) {
        self.kind = kind
        self.color = color
        super.init(frame: .zero)
        isOpaque = false
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var intrinsicContentSize: CGSize { CGSize(width: 9, height: 9) }

    override func draw(_ rect: CGRect) {
        let inset: CGFloat = kind == .remaining ? 0.55 : 0
        let path = UIBezierPath(ovalIn: bounds.insetBy(dx: inset, dy: inset))
        switch kind {
        case .elapsed:
            color.setFill(); path.fill()
        case .remaining:
            path.lineWidth = 1.1
            color.setStroke(); path.stroke()
        }
    }
}

// MARK: - Month index

/// Month abbreviations down the side of the ledger, each on the row where
/// that month begins, so a two-weeks-a-row grid reads like a calendar.
final class MonthIndexView: UIView {
    var start = Date() { didSet { setNeedsDisplay() } }
    var total = 0 { didSet { if total != oldValue { setNeedsDisplay() } } }
    var columns = 14 { didSet { setNeedsDisplay() } }
    var cell: CGFloat = 19 { didSet { setNeedsDisplay() } }
    var maxRows = 22 { didSet { setNeedsDisplay() } }
    var textColor: UIColor = UIColor(white: 1, alpha: 0.35) { didSet { setNeedsDisplay() } }

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
        contentMode = .redraw
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        guard total > 0, columns > 0 else { return }
        let calendar = Calendar.current
        let first = calendar.startOfDay(for: start)
        let rows = min(Int(ceil(Double(total) / Double(columns))), maxRows)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            .foregroundColor: textColor,
            .kern: 1.5
        ]
        var lastMonth: Int?
        for row in 0..<rows {
            // Label the row if it holds the 1st of a month (or the span's first day).
            let rowDays = (row * columns)..<min((row + 1) * columns, total)
            var label: String?
            for offset in rowDays {
                guard let day = calendar.date(byAdding: .day, value: offset, to: first) else { continue }
                let month = calendar.component(.month, from: day)
                if month != lastMonth && (offset == 0 || calendar.component(.day, from: day) == 1) {
                    lastMonth = month
                    label = formatter.string(from: day).uppercased()
                    break
                }
            }
            guard let text = label else { continue }
            let string = NSAttributedString(string: text, attributes: attributes)
            let size = string.size()
            string.draw(at: CGPoint(x: 0, y: cell * (CGFloat(row) + 0.5) - size.height / 2))
        }
    }
}

// MARK: - Navigation container

/// Exists only so the screen has a `navigationItem` the system can host:
/// unfolded, the settings gear is a bar item that iOS places in its vertical
/// bar. The bar itself stays hidden whenever it has nothing to show, and the
/// content controller keeps the say over status bar and orientation.
final class CountdownNavigationController: UINavigationController {
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        isNavigationBarHidden = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var childForStatusBarStyle: UIViewController? { topViewController }
    override var childForStatusBarHidden: UIViewController? { topViewController }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        topViewController?.supportedInterfaceOrientations ?? .portrait
    }
}
