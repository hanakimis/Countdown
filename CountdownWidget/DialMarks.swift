//
//  DialMarks.swift
//  CountdownWidget
//
//  How a countdown maps onto the widget's day dials (Editorial's ring and
//  T-Minus's half-dial). One tick per day reads best, but each dial only has
//  room for so many before neighbouring ticks merge into a solid band — about
//  180 on Editorial's full ring, 90 on T-Minus's half-dial. Longer countdowns
//  zoom out away from today: day ticks around it, then calendar-week blocks,
//  then calendar-month blocks.
//

import Foundation

/// One mark on a day dial: a single day's tick, or a block covering a run of
/// consecutive days in the same calendar week or month.
struct DialMark: Equatable {
    enum Kind { case day, week, month }
    enum State { case elapsed, today, ahead }

    let kind: Kind
    let first: Int       // index of its first day in the span
    var count: Int       // days it covers
    var width = 1.0      // slots it takes on the dial; set by `dialMarks`

    var last: Int { first + count - 1 }

    /// A block only counts as elapsed once every one of its days has passed.
    func state(todayIndex: Int) -> State {
        last < todayIndex ? .elapsed : first <= todayIndex ? .today : .ahead
    }

    /// Room this mark asks for, in day-tick slots. A full block is wider than
    /// a tick but far narrower than its days; a block clipped by the span or
    /// the day ticks shrinks with it.
    var weight: Double {
        switch kind {
        case .day:   return 1
        case .week:  return 2.4 * fullness(of: 7)
        case .month: return 4.5 * fullness(of: 30.4)
        }
    }

    private func fullness(of days: Double) -> Double { min(max(Double(count) / days, 0.45), 1) }
}

/// How far each kind of mark reaches from today, in days.
struct DialZones {
    let pastDays: Int            // day ticks kept behind today
    let futureDays: Int          // day ticks ahead of today
    var weekDays = 56            // then about two months of weeks; months beyond

    func kind(forOffset offset: Int) -> DialMark.Kind {
        let beyond = abs(offset) - (offset < 0 ? pastDays : futureDays)
        if beyond <= 0 { return .day }
        return beyond <= weekDays ? .week : .month
    }
}

/// The marks for a countdown of `total` days with today at `todayIndex`.
/// `today` is any instant within today — it places the week and month
/// boundaries.
func dialMarks(total: Int, todayIndex: Int, today: Date, maxTicks: Int, zones: DialZones,
               calendar: Calendar = .current) -> [DialMark] {
    // Fits: one tick per day.
    guard total > maxTicks else {
        return (0..<max(total, 1)).map { DialMark(kind: .day, first: $0, count: 1) }
    }

    var marks: [DialMark] = []
    var lastBlock: Date?         // start of the last mark's week or month, if it's a block
    for i in 0..<total {
        let offset = i - todayIndex
        let kind = zones.kind(forOffset: offset)
        var block: Date?
        if kind != .day, let day = calendar.date(byAdding: .day, value: offset, to: today) {
            block = calendar.dateInterval(of: kind == .week ? .weekOfYear : .month, for: day)?.start
        }
        if let block, block == lastBlock, marks.last?.kind == kind {
            marks[marks.count - 1].count += 1
        } else {
            marks.append(DialMark(kind: kind, first: i, count: 1))
        }
        lastBlock = block
    }

    // Very long spans still ask for more than the dial holds. Squeeze the
    // blocks into what the day ticks leave, so ticks near today never crowd.
    let dayWidth = Double(marks.filter { $0.kind == .day }.count)
    let blockWeight = marks.reduce(0) { $0 + ($1.kind == .day ? 0 : $1.weight) }
    let squeeze = blockWeight > 0 ? min(1, max(Double(maxTicks) - dayWidth, 0) / blockWeight) : 1
    for i in marks.indices where marks[i].kind != .day {
        marks[i].width = marks[i].weight * squeeze
    }
    return marks
}
