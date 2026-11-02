//
//  CountdownWidget.swift
//  CountdownWidget
//
//  Small home-screen widget showing days left, drawn in whichever visual style
//  is selected in the app. Reads the countdown from the App Group
//  (`CountdownStore`); the app reloads timelines when the date or style changes.
//

import SwiftUI
import WidgetKit

struct CountdownProvider: TimelineProvider {
    /// How many day rollovers to schedule ahead. WidgetKit asks again after the
    /// last one, so this only bounds how stale a timeline can get.
    private let lookahead = 7

    func placeholder(in context: Context) -> CountdownEntry { .sample }

    func getSnapshot(in context: Context, completion: @escaping (CountdownEntry) -> Void) {
        // The widget gallery shows a populated sample rather than an empty countdown.
        completion(context.isPreview && CountdownStore.date == nil ? .sample : Self.entry(at: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountdownEntry>) -> Void) {
        let now = Date()
        var entries = [Self.entry(at: now)]
        if let target = CountdownStore.date {
            // One entry per rollover — the count drops at the target's time of
            // day, not necessarily at midnight.
            var cursor = now
            for _ in 0..<lookahead {
                guard let next = DayCount.nextRollover(after: cursor, to: target) else { break }
                entries.append(Self.entry(at: next))
                cursor = next
            }
        }
        // A finished (or unset) countdown has nothing left to schedule; the app
        // reloads the widget when a new date is picked.
        let finished = entries.count == 1
        completion(Timeline(entries: entries, policy: finished ? .never : .atEnd))
    }

    static func entry(at date: Date) -> CountdownEntry {
        let style = VisualStyle.saved
        guard let target = CountdownStore.date else {
            return CountdownEntry(date: date, style: style, target: nil, remaining: 0, total: 1)
        }
        let remaining = DayCount.remaining(from: date, to: target)
        let total = DayCount.span(start: CountdownStore.startDate ?? date, target: target, remaining: remaining)
        return CountdownEntry(date: date, style: style, target: target, remaining: remaining, total: total)
    }
}

@main
struct CountdownWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "CountdownWidget", provider: CountdownProvider()) { entry in
            CountdownWidgetView(entry: entry)
                .containerBackground(Color(uiColor: entry.style.background), for: .widget)
        }
        .configurationDisplayName("Countdown")
        .description("Days left, in the style you picked in the app.")
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()        // layouts place their own 16 pt margins
    }
}
