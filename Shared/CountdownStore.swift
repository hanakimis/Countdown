//
//  CountdownStore.swift
//  Countdown + CountdownWidget
//
//  The countdown state the home-screen widget renders — target date, start
//  date and visual style — kept in the App Group container so both the app
//  and the widget extension read the same values. Animation preferences
//  (refill / tick-pass / ledger-load styles) stay in `UserDefaults.standard`:
//  the widget can't animate them, so it never needs them.
//

import Foundation

enum CountdownStore {
    static let appGroup = "group.com.hanakimis.countdown"

    /// Falls back to `.standard` if the group container is unavailable (e.g. an
    /// unsigned CI build) so the app keeps working; the widget just won't see it.
    static let defaults = UserDefaults(suiteName: appGroup) ?? .standard

    private enum Key {
        static let date = "date"
        static let startDate = "startDate"
        static let visualStyle = "visualStyle"
        static let migrated = "migratedToAppGroup"
    }

    /// The countdown target, or nil before the user has ever picked one.
    static var date: Date? {
        get { defaults.object(forKey: Key.date) as? Date }
        set { defaults.set(newValue, forKey: Key.date) }
    }

    /// When the current countdown began — sizes the dot grid / day dial span.
    static var startDate: Date? {
        get { defaults.object(forKey: Key.startDate) as? Date }
        set { defaults.set(newValue, forKey: Key.startDate) }
    }

    static var visualStyleRawValue: String? {
        get { defaults.string(forKey: Key.visualStyle) }
        set { defaults.set(newValue, forKey: Key.visualStyle) }
    }

    /// Installs from before the widget kept these keys in `.standard`. Copy them
    /// into the group once, so updating doesn't reset anyone's countdown.
    static func migrateIfNeeded() {
        guard defaults !== UserDefaults.standard, !defaults.bool(forKey: Key.migrated) else { return }
        let old = UserDefaults.standard
        for key in [Key.date, Key.startDate, Key.visualStyle] where defaults.object(forKey: key) == nil {
            if let value = old.object(forKey: key) { defaults.set(value, forKey: key) }
        }
        defaults.set(true, forKey: Key.migrated)
    }
}

// MARK: - Day math

/// Whole-day arithmetic shared by the app's dot ledger and the widget's dials,
/// so both agree on which day is "today".
enum DayCount {
    /// Whole days left until `target`. Rolls over at the target's time of day
    /// (a 7:15 AM target ticks down at 7:15 AM), matching the app's numerals.
    static func remaining(from now: Date, to target: Date, calendar: Calendar = .current) -> Int {
        max(0, calendar.dateComponents([.day], from: now, to: target).day ?? 0)
    }

    /// The countdown's fixed length in days (start → target), never less than
    /// what's left, so a span that predates the current count still fits.
    static func span(start: Date, target: Date, remaining: Int, calendar: Calendar = .current) -> Int {
        let spanDays = calendar.dateComponents([.day], from: start, to: target).day ?? remaining
        return max(spanDays, remaining, 1)
    }

    /// The instant the remaining count next drops (from `remaining` to
    /// `remaining - 1`), or nil once the countdown has finished.
    static func nextRollover(after now: Date, to target: Date, calendar: Calendar = .current) -> Date? {
        let days = remaining(from: now, to: target, calendar: calendar)
        guard target > now,
              let boundary = calendar.date(byAdding: .day, value: -days, to: target) else { return nil }
        // At the boundary itself the count still reads `days`; a second later it's `days - 1`.
        return boundary.addingTimeInterval(1)
    }
}
