//
//  CountdownWidgetViews.swift
//  CountdownWidget
//
//  The small home-screen widget, one layout per app style. Days only: a widget
//  can't run the app's per-second dials, so each style keeps its days block
//  and swaps the hr/min/sec dials for a per-day mark (fortnight dots, a day
//  dial, a cropped half-dial). Layout is specified on a 170 pt canvas (the
//  largest small widget) and scaled to the device's actual size.
//

import SwiftUI
import WidgetKit

struct CountdownEntry: TimelineEntry {
    let date: Date
    let style: VisualStyle
    let target: Date?            // nil until the user picks a date in the app
    let remaining: Int           // whole days left
    let total: Int               // the countdown's fixed span in days

    /// Index of today's day in the span: everything before it has elapsed.
    var todayIndex: Int { total - remaining }

    static let sample = CountdownEntry(date: Date(), style: .ledger,
                                       target: Calendar.current.date(byAdding: .day, value: 58, to: Date()),
                                       remaining: 58, total: 120)
}

struct CountdownWidgetView: View {
    let entry: CountdownEntry

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height) / 170
            Group {
                switch entry.style {
                case .ledger:    LedgerWidget(entry: entry, s: s)
                case .editorial: EditorialWidget(entry: entry, s: s)
                case .tminus:    TMinusWidget(entry: entry, s: s)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
        }
    }
}

// MARK: - Formatting

private enum WidgetFormat {
    static func header(_ entry: CountdownEntry) -> String {
        guard let target = entry.target else { return "SET A DATE" }
        return shortDate.string(from: target).uppercased()
    }

    /// "Dec 25" — or "Dec 25, 7:15 AM" when the user set a time (a target at
    /// exactly midnight is a pure calendar day, as in the app).
    static func until(_ entry: CountdownEntry) -> String {
        guard let target = entry.target else { return "open to set a date" }
        let c = Calendar.current.dateComponents([.hour, .minute], from: target)
        let day = monthDay.string(from: target)
        return (c.hour ?? 0) == 0 && (c.minute ?? 0) == 0 ? day : "\(day), \(time.string(from: target))"
    }

    private static let shortDate = formatter("MMM d, yyyy")
    private static let monthDay = formatter("MMM d")
    private static let time = formatter("h:mm a")
    private static func formatter(_ format: String) -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = format
        return f
    }
}

private extension Font {
    static func serif(_ size: CGFloat) -> Font { .system(size: size, design: .serif) }
}

// MARK: - Ledger · numeral + fortnight

private struct LedgerWidget: View {
    let entry: CountdownEntry
    let s: CGFloat

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 0) {
                Text(WidgetFormat.header(entry))
                    .font(.system(size: 9 * s, weight: .semibold))
                    .kerning(1.8 * s)
                    .foregroundStyle(.white.opacity(0.5))
                Text("\(entry.remaining)")
                    .font(.serif(58 * s).monospacedDigit())
                    .kerning(-1.5 * s)
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(countsDown: true))
                    .padding(.top, 4 * s)
                Text("days remaining")
                    .font(.serif(13 * s).italic())
                    .foregroundStyle(.white.opacity(0.5))
                    .padding(.top, -2 * s)
            }
            .padding(16 * s)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            FortnightDots(entry: entry, s: s)
                .padding(.leading, 16 * s)
                .padding(.bottom, 14 * s)
        }
    }
}

/// A 2 × 10 window onto the app's dot ledger: a week of elapsed days, today,
/// and what's ahead. Today is a plain accent ring — the app's depleting arc
/// would only be right once a day.
private struct FortnightDots: View {
    let entry: CountdownEntry
    let s: CGFloat

    private let columns = 10, rows = 2

    var body: some View {
        let window = columns * rows
        let count = min(window, entry.total)
        // Keep a week of history in view, but never run past the end of the span.
        let first = min(max(entry.todayIndex - 7, 0), max(entry.total - window, 0))
        let pitch = 13.8 * s, radius = 3.8 * s
        let style = entry.style

        Canvas { ctx, _ in
            for i in 0..<count {
                let day = first + i
                let center = CGPoint(x: (CGFloat(i % columns) + 0.5) * pitch,
                                     y: CGFloat(i / columns) * 15 * s + 6 * s)
                let dot = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius,
                                                 width: radius * 2, height: radius * 2))
                if day < entry.todayIndex {
                    ctx.fill(dot, with: .color(Color(uiColor: style.ledgerElapsedDotColor)))
                } else if day == entry.todayIndex {
                    ctx.stroke(dot, with: .color(Color(uiColor: style.accent)), lineWidth: 1.6 * s)
                } else {
                    ctx.stroke(dot, with: .color(.white.opacity(0.28)), lineWidth: 1 * s)
                }
            }
        }
        .frame(width: CGFloat(columns) * pitch, height: (CGFloat(rows - 1) * 15 + 12) * s)
    }
}

// MARK: - Editorial · day dial with the until line

private struct EditorialWidget: View {
    let entry: CountdownEntry
    let s: CGFloat

    var body: some View {
        let ink = Color(uiColor: entry.style.foreground)
        ZStack {
            DayDial(marks: dialMarks(total: entry.total, todayIndex: entry.todayIndex, today: entry.date,
                                     maxTicks: 180, zones: DialZones(pastDays: 7, futureDays: 30)),
                    todayIndex: entry.todayIndex,
                    center: CGPoint(x: 85 * s, y: 85 * s), innerRadius: 64 * s, outerRadius: 78 * s,
                    from: -.pi / 2, to: 1.5 * .pi, closed: true, lineWidth: 1.2 * s,
                    filled: ink.opacity(0.7), track: ink.opacity(0.12),
                    accent: Color(uiColor: entry.style.accent))

            VStack(spacing: 0) {
                Text("\(entry.remaining)")
                    .font(.serif(40 * s).monospacedDigit())
                    .foregroundStyle(ink)
                    .contentTransition(.numericText(countsDown: true))
                    .minimumScaleFactor(0.7)
                Text(entry.target == nil ? "open Countdown\nto set a date" : "days until\n\(WidgetFormat.until(entry))")
                    .font(.serif(11.5 * s).italic())
                    .multilineTextAlignment(.center)
                    .lineSpacing(-1 * s)
                    .foregroundStyle(ink.opacity(0.6))
                    .padding(.top, 1 * s)
            }
            .frame(width: 110 * s)       // stay inside the ring's 128 pt inner diameter
        }
        .frame(width: 170 * s, height: 170 * s)
    }
}

// MARK: - T-Minus · cropped half-dial

private struct TMinusWidget: View {
    let entry: CountdownEntry
    let s: CGFloat

    var body: some View {
        let coral = Color(uiColor: entry.style.accent)
        ZStack(alignment: .topLeading) {
            // Left half of a dial centered off the right edge: 12 o'clock round
            // through 9 to 6, so today's tick is always on screen.
            DayDial(marks: dialMarks(total: entry.total, todayIndex: entry.todayIndex, today: entry.date,
                                     maxTicks: 90, zones: DialZones(pastDays: 5, futureDays: 21)),
                    todayIndex: entry.todayIndex,
                    center: CGPoint(x: 190 * s, y: 90 * s), innerRadius: 52 * s, outerRadius: 92 * s,
                    from: -.pi / 2, to: -1.5 * .pi, closed: false, lineWidth: 1.2 * s,
                    filled: .white.opacity(0.26), track: .white.opacity(0.07), accent: coral)

            VStack(alignment: .leading, spacing: 0) {
                Text("T-MINUS")
                    .font(.system(size: 10 * s, weight: .bold))
                    .kerning(1.4 * s)
                    .foregroundStyle(coral)
                Text("\(entry.remaining)")
                    .font(.system(size: 66 * s, weight: .heavy).monospacedDigit())
                    .kerning(-2.6 * s)
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(countsDown: true))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("DAYS")
                    .font(.system(size: 10 * s, weight: .semibold))
                    .kerning(2 * s)
                    .foregroundStyle(.white.opacity(0.45))
            }
            .padding(16 * s)

            Text(WidgetFormat.header(entry))
                .font(.system(size: 10.5 * s, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 9 * s)
                .padding(.vertical, 4 * s)
                .background(Capsule().fill(.white.opacity(0.07)))
                .overlay(Capsule().strokeBorder(.white.opacity(0.12), lineWidth: 0.5))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                .padding(.leading, 14 * s)
                .padding(.bottom, 13 * s)
        }
    }
}

// MARK: - Day dial

/// Marks between two angles: radial ticks for days (same geometry as the app's
/// `TickDialView`) and ring segments for week / month blocks. Elapsed marks are
/// filled, today is the accent, the rest are track — batched into one path per
/// colour.
private struct DayDial: View {
    let marks: [DialMark]
    let todayIndex: Int
    let center: CGPoint
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let from: Double                 // radians; screen coordinates (y down)
    let to: Double
    let closed: Bool                 // a full ring doesn't repeat its first tick at the end
    let lineWidth: CGFloat
    let filled: Color
    let track: Color
    let accent: Color

    var body: some View {
        Canvas { ctx, _ in
            // Each mark takes `width` slots: a tick sits at its slot's centre,
            // a block spans its slots less a gap at either end.
            let slots = marks.reduce(0) { $0 + $1.width }
            let steps = closed ? slots : max(slots - 1, 1)   // a full ring doesn't repeat its first slot
            let angle = { (slot: Double) in from + slot / steps * (to - from) }
            // Narrower gaps for clipped blocks, so a one-day partial week stays a box.
            let gap = { (mark: DialMark) in min(0.55, mark.width * 0.2) }

            var ticks: [DialMark.State: Path] = [:], blocks: [DialMark.State: Path] = [:]
            var slot = 0.0
            for mark in marks {
                let state = mark.state(todayIndex: todayIndex)
                if mark.kind == .day {
                    let a = angle(slot)
                    ticks[state, default: Path()].move(to: point(a, innerRadius))
                    ticks[state, default: Path()].addLine(to: point(a, outerRadius))
                } else {
                    blocks[state, default: Path()].addPath(sector(from: angle(slot - 0.5 + gap(mark)),
                                                                  to: angle(slot + mark.width - 0.5 - gap(mark))))
                }
                slot += mark.width
            }

            let round = { (w: CGFloat) in StrokeStyle(lineWidth: w, lineCap: .round) }
            for (state, color) in [(DialMark.State.ahead, track), (.elapsed, filled), (.today, accent)] {
                if let path = blocks[state] { ctx.fill(path, with: .color(color)) }
                if let path = ticks[state] {
                    ctx.stroke(path, with: .color(color), style: round(state == .today ? lineWidth * 1.8 : lineWidth))
                }
            }
        }
    }

    private func point(_ angle: Double, _ radius: CGFloat) -> CGPoint {
        CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
    }

    /// A ring segment between the dial's radii. Angles grow clockwise on
    /// screen, which SwiftUI's y-down `addArc` calls `clockwise: false`.
    private func sector(from a0: Double, to a1: Double) -> Path {
        var p = Path()
        p.addArc(center: center, radius: outerRadius, startAngle: .radians(a0), endAngle: .radians(a1),
                 clockwise: a1 < a0)
        p.addArc(center: center, radius: innerRadius, startAngle: .radians(a1), endAngle: .radians(a0),
                 clockwise: a1 > a0)
        p.closeSubpath()
        return p
    }
}
