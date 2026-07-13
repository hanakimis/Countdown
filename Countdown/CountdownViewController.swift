//
//  CountdownViewController.swift
//  Countdown
//
//  Created by Hana Kim on 3/9/15.
//  Copyright (c) 2015 Hana Kim. All rights reserved.
//
//  One countdown screen, three switchable visual styles (Ledger, Editorial,
//  T-Minus). The style is rebuilt programmatically on switch with a short
//  crossfade; a 1 Hz timer drives all numerals and ring values.
//

import UIKit
import UserNotifications

final class CountdownViewController: UIViewController {

    // MARK: - State

    private let defaults = UserDefaults.standard
    private let componentSet: Set<Calendar.Component> = [.day, .hour, .minute, .second]

    private var countdownDate = Date()
    private var startDate = Date()               // when this countdown began — sizes the dot grid's total span
    private var style = VisualStyle.saved
    private var timer: Timer?
    private var didInitialRefill = false
    private var refillWorkItem: DispatchWorkItem?

    /// Everything style-specific lives under this root and is rebuilt on
    /// style switch.
    private let styleRoot = UIView()

    // MARK: - Style-specific references (populated by the builders)

    private var headerDateLabel: UILabel?
    private var daysNumeralLabel: UILabel?
    private var dotLedger: DotLedgerView?

    // Ledger
    private var ledgerDials: [TickDialView] = []          // seconds, minutes, hours
    private var ledgerNumerals: [UILabel] = []

    // Editorial + T-Minus
    private var concentricDial: ConcentricDialView?
    private var unitValueLabels: [UILabel] = []           // hours, minutes, seconds
    private var untilLabel: UILabel?

    // MARK: - Formatting

    private let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"                       // SEP 15, 2026 (uppercased)
        return f
    }()

    private let longDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM d"                            // until September 15
        return f
    }()

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"                            // 3:30 PM
        return f
    }()

    /// A target at exactly 00:00 is treated as a pure calendar-day target:
    /// showing "12:00 AM" there would be noise, so the time is only surfaced
    /// when the user actually set one. Uses the current calendar/time zone so
    /// "midnight" means midnight where the user is.
    private func isMidnight(_ date: Date) -> Bool {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 0) == 0 && (c.minute ?? 0) == 0
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        styleRoot.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(styleRoot)
        NSLayoutConstraint.activate([
            styleRoot.topAnchor.constraint(equalTo: view.topAnchor),
            styleRoot.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            styleRoot.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            styleRoot.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if let saved = defaults.object(forKey: "date") as? Date {
            countdownDate = saved
        }
        // The dot grid drains over the whole span, so it needs to know when the
        // countdown began. Existing installs (saved target, no start) seed to now
        // → the grid starts full today and drains from here.
        if let savedStart = defaults.object(forKey: "startDate") as? Date {
            startDate = savedStart
        } else {
            defaults.set(startDate, forKey: "startDate")
        }

        // Screenshot hook: seed a populated countdown (e.g. SIMCTL_CHILD_SEED_DAYS=64).
        if let seed = ProcessInfo.processInfo.environment["SEED_DAYS"], let d = Int(seed) {
            // Sub-day offset; SEED_SECS shrinks it so a rollover fires soon after
            // launch (for capturing the dissolve animation).
            let subDay = ProcessInfo.processInfo.environment["SEED_SECS"].flatMap(Int.init) ?? (8 * 3600 + 39 * 60 + 16)
            countdownDate = Date().addingTimeInterval(TimeInterval(d * 86400 + subDay))
            startDate = Date()                 // start = now so the seeded span shows a full grid
            // Optional: backdate the start so the grid shows a partial drain
            // (SIMCTL_CHILD_SEED_ELAPSED=20 → 20 days already emptied).
            if let e = ProcessInfo.processInfo.environment["SEED_ELAPSED"], let elapsed = Int(e) {
                startDate = Date().addingTimeInterval(TimeInterval(-elapsed * 86400))
            }
        }
        // Screenshot hook: force a style (SIMCTL_CHILD_STYLE=editorial).
        if let forced = ProcessInfo.processInfo.environment["STYLE"].flatMap(VisualStyle.init) {
            style = forced
        }

        buildInterface()
        updateCountdown()

        timer = Timer.scheduledTimer(timeInterval: 1.0,
                                     target: self,
                                     selector: #selector(updateCountdown),
                                     userInfo: nil,
                                     repeats: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didInitialRefill else { return }
        didInitialRefill = true
        // Volley the rings in on first appearance — slightly delayed so the
        // launch transition doesn't swallow the animation.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { self.refillAllRings() }

        // Screenshot hook: open the settings sheet (SIMCTL_CHILD_SHOW_SETTINGS=1).
        if ProcessInfo.processInfo.environment["SHOW_SETTINGS"] != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { self.openSettings() }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        style.isDark ? .lightContent : .darkContent
    }

    // MARK: - Style switching

    private func switchStyle(to newStyle: VisualStyle) {
        guard newStyle != style else { return }
        style = newStyle
        UIView.transition(with: view, duration: 0.25, options: [.transitionCrossDissolve]) {
            self.buildInterface()
            self.refresh(animateRollovers: false)   // seed the fresh dials silently — no launch volley on a swap
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    private func buildInterface() {
        styleRoot.subviews.forEach { $0.removeFromSuperview() }
        headerDateLabel = nil
        daysNumeralLabel = nil
        dotLedger = nil
        ledgerDials = []
        ledgerNumerals = []
        concentricDial = nil
        unitValueLabels = []
        untilLabel = nil

        view.backgroundColor = style.background
        switch style {
        case .ledger:    buildLedger()
        case .editorial: buildEditorial()
        case .tminus:    buildTMinus()
        }
    }

    // MARK: - Shared pieces

    /// Header row used by Ledger and Editorial: date left, gear right,
    /// 32 pt margins. Tapping either opens the settings sheet.
    private func addHeader(textColor: UIColor, gearColor: UIColor) {
        let date = UILabel()
        date.font = .systemFont(ofSize: 12, weight: .semibold)
        date.textColor = textColor
        date.isUserInteractionEnabled = true
        date.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openSettings)))
        headerDateLabel = date

        let gear = UIButton(type: .system)
        gear.setImage(UIImage(systemName: "gearshape",
                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 17)), for: .normal)
        gear.tintColor = gearColor
        gear.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        [date, gear].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            styleRoot.addSubview($0)
        }
        NSLayoutConstraint.activate([
            date.topAnchor.constraint(equalTo: styleRoot.safeAreaLayoutGuide.topAnchor, constant: 48),
            date.leadingAnchor.constraint(equalTo: styleRoot.leadingAnchor, constant: 32),
            gear.centerYAnchor.constraint(equalTo: date.centerYAnchor),
            gear.trailingAnchor.constraint(equalTo: styleRoot.trailingAnchor, constant: -32)
        ])
    }

    /// The dot ledger block, pinned above the bottom edge.
    private func addDotLedger(accent: UIColor, stroke: UIColor) {
        let ledger = DotLedgerView()
        ledger.accentColor = accent
        ledger.strokeColor = stroke
        dotLedger = ledger

        ledger.translatesAutoresizingMaskIntoConstraints = false
        styleRoot.addSubview(ledger)
        NSLayoutConstraint.activate([
            ledger.leadingAnchor.constraint(equalTo: styleRoot.leadingAnchor, constant: 32),
            ledger.trailingAnchor.constraint(equalTo: styleRoot.trailingAnchor, constant: -32),
            ledger.bottomAnchor.constraint(equalTo: styleRoot.bottomAnchor, constant: -56)
        ])
    }

    // MARK: - Style 1 · Ledger

    private func buildLedger() {
        let white = UIColor.white
        addHeader(textColor: white.withAlphaComponent(0.45),
                  gearColor: white.withAlphaComponent(0.45))

        // Unit rows: seconds, minutes, hours (most volatile first).
        let units: [(total: Int, tickWidth: CGFloat, name: String)] = [
            (60, 1.3, "seconds"), (60, 1.3, "minutes"), (24, 1.6, "hours")
        ]

        var previousRow: UIView?
        for (index, unit) in units.enumerated() {
            let row = UIView()
            row.translatesAutoresizingMaskIntoConstraints = false
            styleRoot.addSubview(row)

            let dial = TickDialView()
            dial.total = unit.total
            dial.tickWidth = unit.tickWidth
            ledgerDials.append(dial)

            let numeral = UILabel()
            numeral.font = Fonts.serif(32, tabular: true)
            numeral.textColor = white
            ledgerNumerals.append(numeral)

            let name = UILabel()
            name.font = .systemFont(ofSize: 13)
            name.textColor = white.withAlphaComponent(0.4)
            name.text = unit.name

            [dial, numeral, name].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                row.addSubview($0)
            }

            let hasSeparator = index < 2
            NSLayoutConstraint.activate([
                dial.topAnchor.constraint(equalTo: row.topAnchor),
                dial.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                dial.widthAnchor.constraint(equalToConstant: 56),
                dial.heightAnchor.constraint(equalToConstant: 56),
                numeral.centerYAnchor.constraint(equalTo: dial.centerYAnchor),
                numeral.leadingAnchor.constraint(equalTo: dial.trailingAnchor, constant: 18),
                numeral.widthAnchor.constraint(greaterThanOrEqualToConstant: 56),
                name.centerYAnchor.constraint(equalTo: dial.centerYAnchor),
                name.leadingAnchor.constraint(equalTo: numeral.trailingAnchor, constant: 18),
                row.bottomAnchor.constraint(equalTo: dial.bottomAnchor, constant: hasSeparator ? 14 : 0)
            ])

            if hasSeparator {
                let line = UIView()
                line.backgroundColor = white.withAlphaComponent(0.08)
                line.translatesAutoresizingMaskIntoConstraints = false
                row.addSubview(line)
                NSLayoutConstraint.activate([
                    line.leadingAnchor.constraint(equalTo: row.leadingAnchor),
                    line.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                    line.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                    line.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale)
                ])
            }

            NSLayoutConstraint.activate([
                row.leadingAnchor.constraint(equalTo: styleRoot.leadingAnchor, constant: 32),
                row.trailingAnchor.constraint(equalTo: styleRoot.trailingAnchor, constant: -32),
                previousRow.map { row.topAnchor.constraint(equalTo: $0.bottomAnchor, constant: 16) }
                    ?? row.topAnchor.constraint(equalTo: headerDateLabel!.bottomAnchor, constant: 36)
            ])
            previousRow = row
        }

        // Days block
        let days = UILabel()
        days.font = Fonts.serif(72, tabular: true)
        days.textColor = white
        daysNumeralLabel = days

        let caption = UILabel()
        caption.font = Fonts.serif(18, italic: true)
        caption.textColor = white.withAlphaComponent(0.5)
        caption.text = "days remaining"

        [days, caption].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            styleRoot.addSubview($0)
        }

        addDotLedger(accent: style.accent,
                     stroke: white.withAlphaComponent(0.28))

        // The days block sits just above the dot grid (bottom-up), riding along
        // as the grid's height changes with the day count.
        NSLayoutConstraint.activate([
            days.leadingAnchor.constraint(equalTo: styleRoot.leadingAnchor, constant: 32),
            caption.leadingAnchor.constraint(equalTo: days.leadingAnchor),
            caption.topAnchor.constraint(equalTo: days.bottomAnchor, constant: 6),
            caption.bottomAnchor.constraint(equalTo: dotLedger!.topAnchor, constant: -20)
        ])
    }

    // MARK: - Style 2 · Editorial

    private func buildEditorial() {
        let ink = style.foreground
        addHeader(textColor: ink.withAlphaComponent(0.5),
                  gearColor: ink.withAlphaComponent(0.4))

        let dial = ConcentricDialView()
        dial.ringFilledColors = style.concentricFilledColors
        dial.trackColor = style.trackColor
        dial.accentColor = style.accent
        dial.tickWidth = 1.9
        dial.selectedTickWidth = 2.5
        concentricDial = dial

        // Dial center: serif days numeral over an SF "days" caption. Big at 1–2
        // digits; auto-shrinks so a 3-digit count doesn't crowd the inner ring.
        let days = UILabel()
        days.font = Fonts.serif(52, tabular: true)
        days.textColor = ink
        days.textAlignment = .center
        days.adjustsFontSizeToFitWidth = true
        days.minimumScaleFactor = 0.55
        daysNumeralLabel = days

        let daysCaption = UILabel()
        daysCaption.font = .systemFont(ofSize: 15)
        daysCaption.textColor = ink.withAlphaComponent(0.5)
        daysCaption.text = "days"

        let until = UILabel()
        until.font = Fonts.serif(18, italic: true)
        until.textColor = ink.withAlphaComponent(0.55)
        untilLabel = until

        // Units row: live hr / min / sec, centered.
        let unitsRow = UIStackView()
        unitsRow.axis = .horizontal
        unitsRow.spacing = 26
        unitsRow.alignment = .lastBaseline
        for abbreviation in ["hr", "min", "sec"] {
            let value = UILabel()
            value.font = Fonts.serif(24, tabular: true)
            value.textColor = ink
            unitValueLabels.append(value)

            let unit = UILabel()
            unit.font = .systemFont(ofSize: 12)
            unit.textColor = ink.withAlphaComponent(0.45)
            unit.text = abbreviation

            let group = UIStackView(arrangedSubviews: [value, unit])
            group.axis = .horizontal
            group.spacing = 4
            group.alignment = .lastBaseline
            unitsRow.addArrangedSubview(group)
        }

        [dial, days, daysCaption, until, unitsRow].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            styleRoot.addSubview($0)
        }
        NSLayoutConstraint.activate([
            dial.topAnchor.constraint(equalTo: headerDateLabel!.bottomAnchor, constant: 56),
            dial.centerXAnchor.constraint(equalTo: styleRoot.centerXAnchor),
            dial.widthAnchor.constraint(equalToConstant: 252),
            dial.heightAnchor.constraint(equalToConstant: 252),

            days.centerXAnchor.constraint(equalTo: dial.centerXAnchor),
            days.centerYAnchor.constraint(equalTo: dial.centerYAnchor, constant: -10),
            days.widthAnchor.constraint(equalTo: dial.widthAnchor, multiplier: 0.26),  // keep the numeral inside the inner ring

            daysCaption.centerXAnchor.constraint(equalTo: dial.centerXAnchor),
            daysCaption.topAnchor.constraint(equalTo: days.bottomAnchor, constant: -2),

            until.centerXAnchor.constraint(equalTo: styleRoot.centerXAnchor),
            until.topAnchor.constraint(equalTo: dial.bottomAnchor, constant: 24),

            unitsRow.centerXAnchor.constraint(equalTo: styleRoot.centerXAnchor),
            unitsRow.topAnchor.constraint(equalTo: until.bottomAnchor, constant: 28)
        ])

        addDotLedger(accent: style.accent,
                     stroke: ink.withAlphaComponent(0.35))
    }

    // MARK: - Style 3 · T-Minus

    private func buildTMinus() {
        let white = UIColor.white
        let coral = style.accent

        // Concentric dial cropped off the right edge: 620 pt, vertically
        // centered, right edge 230 pt past the screen.
        let dial = ConcentricDialView()
        dial.ringFilledColors = style.concentricFilledColors
        dial.trackColor = style.trackColor
        dial.accentColor = coral
        dial.tickWidth = 3.6
        dial.selectedTickWidth = 4.6
        concentricDial = dial

        // Type block
        let tminus = UILabel()
        tminus.font = .systemFont(ofSize: 13, weight: .bold)
        tminus.textColor = coral
        tminus.setText("T-MINUS", kern: 3)

        let days = UILabel()
        days.font = .monospacedDigitSystemFont(ofSize: 120, weight: .heavy)
        days.textColor = white
        daysNumeralLabel = days

        let daysCaption = UILabel()
        daysCaption.font = .systemFont(ofSize: 15, weight: .semibold)
        daysCaption.textColor = white.withAlphaComponent(0.45)
        daysCaption.setText("DAYS", kern: 4)

        // Unit stack: live HR / MIN / SEC values.
        let unitStack = UIStackView()
        unitStack.axis = .vertical
        unitStack.alignment = .leading
        unitStack.spacing = 16
        for unitName in ["HR", "MIN", "SEC"] {
            let value = UILabel()
            value.font = .monospacedDigitSystemFont(ofSize: 32, weight: .bold)
            value.textColor = coral
            unitValueLabels.append(value)

            let unit = UILabel()
            unit.font = .systemFont(ofSize: 12, weight: .semibold)
            unit.textColor = white.withAlphaComponent(0.4)
            unit.setText(unitName, kern: 2)

            let row = UIStackView(arrangedSubviews: [value, unit])
            row.axis = .horizontal
            row.spacing = 8
            row.alignment = .lastBaseline
            unitStack.addArrangedSubview(row)
        }

        // Bottom pill: date + gear, opens the settings sheet.
        let pillHeight: CGFloat = 42
        let pill = UIControl()
        pill.backgroundColor = UIColor(white: 1, alpha: 0.06)
        pill.layer.borderWidth = 0.5
        pill.layer.borderColor = UIColor(white: 1, alpha: 0.1).cgColor
        pill.layer.cornerRadius = pillHeight / 2      // capsule; radius is layout-independent
        pill.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        let pillDate = UILabel()
        pillDate.font = .systemFont(ofSize: 15, weight: .semibold)
        pillDate.textColor = white
        pillDate.isUserInteractionEnabled = false
        headerDateLabel = pillDate

        let divider = UIView()
        divider.backgroundColor = UIColor(white: 1, alpha: 0.1)
        divider.isUserInteractionEnabled = false

        let gear = UIImageView(image: UIImage(systemName: "gearshape",
                                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 13)))
        gear.tintColor = white.withAlphaComponent(0.5)

        [pillDate, divider, gear].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            pill.addSubview($0)
        }

        [dial, tminus, days, daysCaption, unitStack, pill].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            styleRoot.addSubview($0)
        }

        NSLayoutConstraint.activate([
            dial.widthAnchor.constraint(equalToConstant: 620),
            dial.heightAnchor.constraint(equalToConstant: 620),
            dial.centerYAnchor.constraint(equalTo: styleRoot.centerYAnchor),
            dial.trailingAnchor.constraint(equalTo: styleRoot.trailingAnchor, constant: 230),

            tminus.topAnchor.constraint(equalTo: styleRoot.safeAreaLayoutGuide.topAnchor, constant: 90),
            tminus.leadingAnchor.constraint(equalTo: styleRoot.leadingAnchor, constant: 28),
            days.topAnchor.constraint(equalTo: tminus.bottomAnchor, constant: 8),
            days.leadingAnchor.constraint(equalTo: tminus.leadingAnchor, constant: -4),
            daysCaption.topAnchor.constraint(equalTo: days.bottomAnchor, constant: 6),
            daysCaption.leadingAnchor.constraint(equalTo: tminus.leadingAnchor),

            unitStack.leadingAnchor.constraint(equalTo: styleRoot.leadingAnchor, constant: 28),
            unitStack.bottomAnchor.constraint(equalTo: styleRoot.bottomAnchor, constant: -170),

            pill.leadingAnchor.constraint(equalTo: styleRoot.leadingAnchor, constant: 28),
            pill.bottomAnchor.constraint(equalTo: styleRoot.bottomAnchor, constant: -52),
            pill.heightAnchor.constraint(equalToConstant: pillHeight),

            pillDate.topAnchor.constraint(equalTo: pill.topAnchor, constant: 11),
            pillDate.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -11),
            pillDate.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 18),
            divider.leadingAnchor.constraint(equalTo: pillDate.trailingAnchor, constant: 12),
            divider.widthAnchor.constraint(equalToConstant: 1),
            divider.topAnchor.constraint(equalTo: pill.topAnchor, constant: 12),
            divider.bottomAnchor.constraint(equalTo: pill.bottomAnchor, constant: -12),
            gear.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
            gear.leadingAnchor.constraint(equalTo: divider.trailingAnchor, constant: 12),
            gear.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -18)
        ])
    }

    // MARK: - Settings

    @objc private func openSettings() {
        let sheet = SettingsSheetViewController(currentDate: countdownDate)
        sheet.delegate = self
        present(sheet, animated: true)
    }

    // MARK: - Countdown updates

    /// Timer selector: a live tick, so genuine rollovers animate.
    @objc private func updateCountdown() { refresh(animateRollovers: true) }

    /// Repaints every numeral and ring from `countdownDate`. `animateRollovers`
    /// distinguishes a live second-tick (a value jumping up is a real rollover
    /// → volley) from a silent rebuild or date scrub (seed the values, no
    /// volley); the intentional sweep is driven separately by `refillAllRings`.
    private func refresh(animateRollovers: Bool) {
        let components = Calendar.current.dateComponents(componentSet, from: Date(), to: countdownDate)
        let days = max(0, components.day ?? 0)
        let hours = max(0, components.hour ?? 0)
        let minutes = max(0, components.minute ?? 0)
        let seconds = max(0, components.second ?? 0)

        var shortDate = shortDateFormatter.string(from: countdownDate).uppercased()
        if !isMidnight(countdownDate) {
            shortDate += "  " + timeFormatter.string(from: countdownDate).uppercased()
        }

        switch style {
        case .ledger:
            headerDateLabel?.setText(shortDate, kern: 2.5)
            daysNumeralLabel?.setText("\(days)", kern: -2)
            for (dial, value) in zip(ledgerDials, [seconds, minutes, hours]) { dial.setValue(value, animated: animateRollovers) }
            for (label, value) in zip(ledgerNumerals, [seconds, minutes, hours]) { label.text = "\(value)" }
        case .editorial:
            headerDateLabel?.setText(shortDate, kern: 2.5)
            daysNumeralLabel?.text = "\(days)"
            var until = "until \(longDateFormatter.string(from: countdownDate))"
            if !isMidnight(countdownDate) {
                until += " at \(timeFormatter.string(from: countdownDate))"
            }
            untilLabel?.text = until
            concentricDial?.setValues(seconds: seconds, minutes: minutes, hours: hours, animated: animateRollovers)
            for (label, value) in zip(unitValueLabels, [hours, minutes, seconds]) { label.text = "\(value)" }
        case .tminus:
            headerDateLabel?.text = shortDate
            daysNumeralLabel?.setText("\(days)", kern: -4)
            concentricDial?.setValues(seconds: seconds, minutes: minutes, hours: hours, animated: animateRollovers)
            for (label, value) in zip(unitValueLabels, [hours, minutes, seconds]) { label.text = "\(value)" }
        }

        // Total span = whole journey from start to target; the grid holds that
        // many dots: `days` solid, one current-day gauge, the rest elapsed.
        // `dayFraction` is how much of the current day is still left, so the
        // gauge on the leading dot depletes with the hours/minutes/seconds.
        let spanDays = Calendar.current.dateComponents([.day], from: startDate, to: countdownDate).day ?? days
        let totalDays = max(spanDays, days + 1, 1)          // +1 leaves room for the current-day dot
        let dayFraction = CGFloat(hours * 3600 + minutes * 60 + seconds) / 86_400
        dotLedger?.setValues(total: totalDays, wholeDays: days, dayFraction: dayFraction, animated: animateRollovers)
        updateBadge(days: days)          // keep the home-screen badge in step with the on-screen count
    }

    private func refillAllRings() {
        ledgerDials.forEach { $0.refill() }
        concentricDial?.refillAll()
    }

    /// Coalesces the launch volley to a single sweep after a burst of date
    /// changes (the wheel picker fires continuously while decelerating).
    private func scheduleRefillVolley() {
        refillWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.refillAllRings() }
        refillWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
    }

    private var lastBadgeDays: Int?

    private func updateBadge(days: Int) {
        let count = max(0, days)
        guard count != lastBadgeDays else { return }   // avoid redundant per-second writes
        lastBadgeDays = count
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(count)
        } else {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
}

// MARK: - Settings sheet delegate

extension CountdownViewController: SettingsSheetDelegate {
    func settingsSheet(_ sheet: SettingsSheetViewController, didSelect style: VisualStyle) {
        VisualStyle.saved = style
        switchStyle(to: style)                 // re-renders instantly behind the sheet
        applyIcon(for: style)                  // swap the home-screen icon to match
    }

    /// Switches the home-screen app icon to match the chosen style.
    ///
    /// Ledger is the asset-catalog *primary*, selected by passing `nil`;
    /// Editorial and T-Minus are loose alternate icons declared in Info.plist
    /// under `CFBundleAlternateIcons`. `setAlternateIconName` always shows a
    /// one-time system alert, so this fires ONLY when the icon actually
    /// changes — never redundantly, and never on launch.
    private func applyIcon(for style: VisualStyle) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        let name: String?
        switch style {
        case .ledger:    name = nil                    // restore the primary
        case .editorial: name = "AppIcon-Editorial"
        case .tminus:    name = "AppIcon-TMinus"
        }
        guard UIApplication.shared.alternateIconName != name else { return }
        UIApplication.shared.setAlternateIconName(name)
    }

    func settingsSheet(_ sheet: SettingsSheetViewController, didPick date: Date) {
        countdownDate = date
        defaults.set(date, forKey: "date")
        startDate = Date()                     // a freshly picked target restarts the span → grid fills up
        defaults.set(startDate, forKey: "startDate")
        refresh(animateRollovers: false)       // update numerals now, without per-wheel-step volleys
        scheduleRefillVolley()                  // one clean sweep once the wheel settles
    }
}
