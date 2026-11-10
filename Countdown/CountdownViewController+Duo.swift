//
//  CountdownViewController+Duo.swift
//  Countdown
//
//  The foldable layouts. Unfolded (hinge vertical) the screen becomes a
//  two-panel spread whose settings gear sits in the system's vertical bar; half-open with
//  the hinge horizontal it becomes a table-top clock. Nothing interactive, and
//  no single glyph, sits on the fold: the hinge is always a gutter.
//
//  There is no fold-geometry API, so the fold is taken to be the scene's
//  midline (true for the Duo's inner display in both poses).
//

import UIKit

extension CountdownViewController {

    // MARK: - Layout selection

    /// Chooses the arrangement from the scene size and the hinge.
    func resolveLayout(for size: CGSize) -> CountdownLayout {
        if let forcedLayout { return forcedLayout }
        // Half-open and turned so the hinge runs horizontally.
        if hingeIsPartiallyOpen, size.height > size.width, size.height >= 900 { return .tabletop }
        if size.width >= 700, size.width > size.height { return .spread }
        // The Duo's outer display (678 pt) and the smallest iPhones are short.
        return .compact(short: size.height < 720)
    }

    /// Landscape is only offered while a large display is half-open, so the
    /// inner display can turn into the table-top pose. Everything else stays portrait.
    var tabletopAllowed: Bool {
        hingeIsPartiallyOpen && max(view.bounds.width, view.bounds.height) >= 900
    }

    /// The vertical bar can appear or leave without the layout changing.
    func observeVerticalBar() {
        guard #available(iOS 27.1, *) else { return }
        registerForTraitChanges(UITraitCollection.systemTraitsAffectingVerticalBarEdge) { (self: Self, _) in
            let hosted = self.systemBarGear.map { self.navigationItem.rightBarButtonItems?.contains($0) ?? false } ?? false
            guard hosted != self.gearInSystemBar else { return }
            UIView.performWithoutAnimation {
                self.buildInterface()
                self.refresh(animateRollovers: false)
            }
        }
    }

    func observeHinge() {
        guard #available(iOS 27.1, *) else { return }
        let interaction = UIHingeInteraction { [weak self] _, update in
            guard let self else { return }
            let partial = update.hinge?.status == .partiallyOpen
            guard partial != self.hingeIsPartiallyOpen else { return }
            self.hingeIsPartiallyOpen = partial
            self.setNeedsUpdateOfSupportedInterfaceOrientations()
            self.navigationController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            self.view.setNeedsLayout()          // viewDidLayoutSubviews re-resolves the layout
        }
        view.addInteraction(interaction)
    }

    // MARK: - Spread · Hero & Ledger

    /// Left panel: the phone hero (header, unit rows, today, days numeral).
    /// Right panel: the whole span as a calendar-shaped ledger, two weeks a
    /// row with a month index. The hero's "today" is the same gauge glyph as
    /// the ledger's today dot, which wears a halo; tapping it pulses the grid.
    func buildLedgerSpread() {
        let ink = style.foreground
        addHeader(textColor: ink.withAlphaComponent(0.45), gearColor: ink.withAlphaComponent(0.45))
        let header = headerDateLabel!
        let fold = styleRoot.centerXAnchor

        addLedgerUnitRows(below: header.bottomAnchor, gap: 36, trailing: fold, tight: false)

        // Days block, bottom-anchored.
        let days = UILabel()
        days.font = Fonts.serif(72, tabular: true)
        days.textColor = ink
        daysNumeralLabel = days

        let daysCaption = UILabel()
        daysCaption.font = Fonts.serif(18, italic: true)
        daysCaption.textColor = ink.withAlphaComponent(0.5)
        daysCaption.text = "days remaining"

        // Today block: the gauge, its caption, and a faint leader running to
        // the fold, pointing across at the same day in the ledger.
        let today = UIControl()
        today.accessibilityTraits = .button
        today.accessibilityLabel = "Today"
        today.addTarget(self, action: #selector(todayTapped), for: .touchUpInside)

        let gauge = TodayGaugeView()
        gauge.accentColor = style.accent
        gauge.trackColor = style.ledgerStrokeColor
        gauge.isUserInteractionEnabled = false
        duo.todayGauge = gauge

        let todayCaption = UILabel()
        todayCaption.font = .systemFont(ofSize: 11, weight: .semibold)
        todayCaption.textColor = style.accent
        todayCaption.isUserInteractionEnabled = false
        duo.todayCaption = todayCaption

        let leader = HairlineView()
        leader.backgroundColor = style.accent.withAlphaComponent(0.3)

        [gauge, todayCaption].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            today.addSubview($0)
        }
        [days, daysCaption, today, leader].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            styleRoot.addSubview($0)
        }

        // Right panel.
        let right = rightPanelGuide(leadingInset: 32)

        let span = UILabel()
        span.font = .systemFont(ofSize: 12, weight: .semibold)
        span.textColor = ink.withAlphaComponent(0.45)
        duo.spanCaption = span

        let ledger = makeDotLedger(accent: style.accent, stroke: style.ledgerStrokeColor,
                                   elapsed: style.ledgerElapsedDotColor)
        ledger.columns = 14                                 // two weeks a row
        ledger.cell = 19
        ledger.maxRows = 22                                 // 308 days on the panel
        ledger.emphasizesToday = true

        let months = MonthIndexView()
        months.columns = ledger.columns
        months.cell = ledger.cell
        months.maxRows = ledger.maxRows
        months.textColor = ink.withAlphaComponent(0.35)
        duo.monthIndex = months

        let legend = makeLegend(ink: ink)

        let since = UILabel()
        since.font = Fonts.serif(18, italic: true)
        since.textColor = ink.withAlphaComponent(0.5)
        duo.sinceLabel = since

        [span, months, legend, since].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            styleRoot.addSubview($0)
        }

        NSLayoutConstraint.activate([
            days.leadingAnchor.constraint(equalTo: styleRoot.leadingAnchor, constant: 32),
            daysCaption.leadingAnchor.constraint(equalTo: days.leadingAnchor),
            daysCaption.topAnchor.constraint(equalTo: days.bottomAnchor, constant: 6),
            daysCaption.bottomAnchor.constraint(equalTo: styleRoot.bottomAnchor, constant: -56),

            today.leadingAnchor.constraint(equalTo: styleRoot.leadingAnchor, constant: 32),
            today.bottomAnchor.constraint(equalTo: days.topAnchor, constant: -24),
            gauge.leadingAnchor.constraint(equalTo: today.leadingAnchor),
            gauge.topAnchor.constraint(equalTo: today.topAnchor, constant: 8),
            gauge.bottomAnchor.constraint(equalTo: today.bottomAnchor, constant: -8),
            gauge.widthAnchor.constraint(equalToConstant: 28),
            gauge.heightAnchor.constraint(equalToConstant: 28),
            todayCaption.leadingAnchor.constraint(equalTo: gauge.trailingAnchor, constant: 14),
            todayCaption.centerYAnchor.constraint(equalTo: gauge.centerYAnchor),
            todayCaption.trailingAnchor.constraint(equalTo: today.trailingAnchor),

            leader.leadingAnchor.constraint(equalTo: today.trailingAnchor, constant: 14),
            leader.trailingAnchor.constraint(equalTo: fold, constant: -24),
            leader.centerYAnchor.constraint(equalTo: gauge.centerYAnchor),

            span.leadingAnchor.constraint(equalTo: right.leadingAnchor),
            span.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            months.leadingAnchor.constraint(equalTo: right.leadingAnchor),
            months.widthAnchor.constraint(equalToConstant: 34),
            months.topAnchor.constraint(equalTo: ledger.topAnchor),
            months.heightAnchor.constraint(equalTo: ledger.heightAnchor),

            ledger.leadingAnchor.constraint(equalTo: months.trailingAnchor),
            ledger.trailingAnchor.constraint(equalTo: right.trailingAnchor),
            ledger.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 36),

            legend.leadingAnchor.constraint(equalTo: ledger.leadingAnchor),
            legend.topAnchor.constraint(equalTo: ledger.bottomAnchor, constant: 18),

            since.leadingAnchor.constraint(equalTo: right.leadingAnchor),
            since.bottomAnchor.constraint(equalTo: styleRoot.bottomAnchor, constant: -56)
        ])
    }

    @objc private func todayTapped() {
        dotLedger?.pulseToday()
    }

    /// "● spent  ◐ today, 31% left  ○ remaining"
    private func makeLegend(ink: UIColor) -> UIStackView {
        func text(_ string: String) -> UILabel {
            let label = UILabel()
            label.font = .systemFont(ofSize: 11)
            label.textColor = ink.withAlphaComponent(0.4)
            label.text = string
            return label
        }
        func item(_ glyph: UIView, _ label: UILabel) -> UIStackView {
            glyph.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                glyph.widthAnchor.constraint(equalToConstant: 9),
                glyph.heightAnchor.constraint(equalToConstant: 9)
            ])
            let stack = UIStackView(arrangedSubviews: [glyph, label])
            stack.spacing = 6
            stack.alignment = .center
            return stack
        }
        let todayGlyph = TodayGaugeView()
        todayGlyph.accentColor = style.accent
        todayGlyph.trackColor = style.ledgerStrokeColor
        todayGlyph.fraction = 0.66
        let todayText = text("today")
        duo.legendTodayLabel = todayText

        let legend = UIStackView(arrangedSubviews: [
            item(LedgerGlyphView(kind: .elapsed, color: style.ledgerElapsedDotColor), text("spent")),
            item(todayGlyph, todayText),
            item(LedgerGlyphView(kind: .remaining, color: style.ledgerStrokeColor), text("remaining"))
        ])
        legend.spacing = 16
        legend.alignment = .center
        return legend
    }

    /// The area right of the fold and inside the safe area (which already
    /// stops short of the system's vertical bar).
    private func rightPanelGuide(leadingInset: CGFloat, trailingInset: CGFloat = 24) -> UILayoutGuide {
        let guide = UILayoutGuide()
        styleRoot.addLayoutGuide(guide)
        NSLayoutConstraint.activate([
            guide.leadingAnchor.constraint(equalTo: styleRoot.centerXAnchor, constant: leadingInset),
            guide.trailingAnchor.constraint(equalTo: styleRoot.safeAreaLayoutGuide.trailingAnchor, constant: -trailingInset),
            guide.topAnchor.constraint(equalTo: styleRoot.topAnchor),
            guide.bottomAnchor.constraint(equalTo: styleRoot.bottomAnchor)
        ])
        return guide
    }

    // MARK: - Spread · Editorial

    /// Left page: the instrument (the concentric dial, large, with the live
    /// hr / min / sec). Right page: the summary (the days numeral as display
    /// type, the target, the started / spent / left figures, the whole span).
    func buildEditorialSpread() {
        let ink = style.foreground
        addHeader(textColor: ink.withAlphaComponent(0.5), gearColor: ink.withAlphaComponent(0.4))
        let header = headerDateLabel!

        let left = UILayoutGuide()
        styleRoot.addLayoutGuide(left)

        let dial = ConcentricDialView()
        dial.ringFilledColors = style.concentricFilledColors
        dial.trackColor = style.trackColor
        dial.accentColor = style.accent
        dial.tickWidth = 2.1
        dial.selectedTickWidth = 2.8
        concentricDial = dial

        let unitsRow = UIStackView()
        unitsRow.axis = .horizontal
        unitsRow.spacing = 30
        unitsRow.alignment = .lastBaseline
        for abbreviation in ["hr", "min", "sec"] {
            let value = UILabel()
            value.font = Fonts.serif(30, tabular: true)
            value.textColor = ink
            unitValueLabels.append(value)

            let unit = UILabel()
            unit.font = .systemFont(ofSize: 13)
            unit.textColor = ink.withAlphaComponent(0.45)
            unit.text = abbreviation

            let group = UIStackView(arrangedSubviews: [value, unit])
            group.axis = .horizontal
            group.spacing = 5
            group.alignment = .lastBaseline
            unitsRow.addArrangedSubview(group)
        }

        // Right page.
        let right = rightPanelGuide(leadingInset: 40)

        let days = UILabel()
        days.font = Fonts.serif(112, tabular: true)
        days.textColor = ink
        days.adjustsFontSizeToFitWidth = true
        days.minimumScaleFactor = 0.6
        daysNumeralLabel = days

        let daysCaption = UILabel()
        daysCaption.font = Fonts.serif(20, italic: true)
        daysCaption.textColor = ink.withAlphaComponent(0.5)
        daysCaption.text = "days remaining"

        let until = UILabel()
        until.font = Fonts.serif(18, italic: true)
        until.textColor = ink.withAlphaComponent(0.55)
        untilLabel = until

        let rule = HairlineView()
        rule.backgroundColor = ink.withAlphaComponent(0.12)

        let meta = UIStackView()
        meta.axis = .horizontal
        meta.distribution = .fillEqually
        for title in ["STARTED", "SPENT", "LEFT"] {
            let caption = UILabel()
            caption.font = .systemFont(ofSize: 10, weight: .semibold)
            caption.textColor = ink.withAlphaComponent(0.45)
            caption.setText(title, kern: 1.5)

            let value = UILabel()
            value.font = Fonts.serif(20, tabular: true)
            value.textColor = ink
            duo.metaValueLabels.append(value)

            let column = UIStackView(arrangedSubviews: [caption, value])
            column.axis = .vertical
            column.spacing = 4
            column.alignment = .leading
            meta.addArrangedSubview(column)
        }

        let span = UILabel()
        span.font = .systemFont(ofSize: 11, weight: .semibold)
        span.textColor = ink.withAlphaComponent(0.45)
        duo.spanCaption = span

        let ledger = makeDotLedger(accent: style.accent, stroke: style.ledgerStrokeColor,
                                   elapsed: style.ledgerElapsedDotColor)
        ledger.columns = 16
        ledger.cell = 17
        ledger.maxRows = 12

        [dial, unitsRow, days, daysCaption, until, rule, meta, span].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            styleRoot.addSubview($0)
        }

        NSLayoutConstraint.activate([
            left.leadingAnchor.constraint(equalTo: styleRoot.leadingAnchor),
            left.trailingAnchor.constraint(equalTo: styleRoot.centerXAnchor),

            dial.centerXAnchor.constraint(equalTo: left.centerXAnchor),
            dial.centerYAnchor.constraint(equalTo: styleRoot.centerYAnchor, constant: -16),
            dial.widthAnchor.constraint(equalToConstant: 320),
            dial.heightAnchor.constraint(equalToConstant: 320),
            dial.topAnchor.constraint(greaterThanOrEqualTo: header.bottomAnchor, constant: 24),

            unitsRow.centerXAnchor.constraint(equalTo: left.centerXAnchor),
            unitsRow.topAnchor.constraint(equalTo: dial.bottomAnchor, constant: 32),

            days.leadingAnchor.constraint(equalTo: right.leadingAnchor, constant: -4),
            days.trailingAnchor.constraint(lessThanOrEqualTo: right.trailingAnchor),
            days.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 16),
            daysCaption.leadingAnchor.constraint(equalTo: right.leadingAnchor),
            daysCaption.topAnchor.constraint(equalTo: days.lastBaselineAnchor, constant: 10),
            until.leadingAnchor.constraint(equalTo: right.leadingAnchor),
            until.topAnchor.constraint(equalTo: daysCaption.bottomAnchor, constant: 10),

            rule.leadingAnchor.constraint(equalTo: right.leadingAnchor),
            rule.trailingAnchor.constraint(equalTo: right.trailingAnchor),
            rule.topAnchor.constraint(equalTo: until.bottomAnchor, constant: 22),
            meta.leadingAnchor.constraint(equalTo: right.leadingAnchor),
            meta.trailingAnchor.constraint(equalTo: right.trailingAnchor),
            meta.topAnchor.constraint(equalTo: rule.bottomAnchor, constant: 16),

            // The span follows the figures directly, so a short span leaves
            // the space below the grid rather than a gap above it.
            span.leadingAnchor.constraint(equalTo: right.leadingAnchor),
            span.topAnchor.constraint(equalTo: meta.bottomAnchor, constant: 28),
            ledger.topAnchor.constraint(equalTo: span.bottomAnchor, constant: 12),
            ledger.leadingAnchor.constraint(equalTo: right.leadingAnchor),
            ledger.trailingAnchor.constraint(equalTo: right.trailingAnchor),
            ledger.bottomAnchor.constraint(lessThanOrEqualTo: styleRoot.bottomAnchor, constant: -40)
        ])
    }

    // MARK: - Spread · T-Minus whole dial

    /// The phone's cropped dial becomes the whole instrument on the right
    /// panel; the type block and pill keep the left.
    func buildTMinusSpread() {
        let right = rightPanelGuide(leadingInset: 16, trailingInset: 16)
        buildTMinus { dial in
            dial.tickWidth = 2.6
            dial.selectedTickWidth = 3.4
            let size = dial.widthAnchor.constraint(equalTo: right.widthAnchor)
            size.priority = .defaultHigh
            return [
                dial.centerXAnchor.constraint(equalTo: right.centerXAnchor),
                dial.centerYAnchor.constraint(equalTo: self.styleRoot.centerYAnchor),
                size,
                dial.widthAnchor.constraint(lessThanOrEqualToConstant: 360),
                dial.heightAnchor.constraint(lessThanOrEqualTo: self.styleRoot.heightAnchor, constant: -96),
                dial.heightAnchor.constraint(equalTo: dial.widthAnchor)
            ]
        }
    }

    // MARK: - Table-top clock

    /// Half-open on a desk. The upright panel is a clock face read from
    /// across the room; the flat panel holds what you touch. A 24 pt band each
    /// side of the hinge stays empty.
    func buildTabletop() {
        let ink = style.foreground
        let fold = styleRoot.centerYAnchor
        let safe = styleRoot.safeAreaLayoutGuide
        let isTMinus = style == .tminus

        // Upper panel.
        let header = UILabel()
        header.font = .systemFont(ofSize: 12, weight: .semibold)
        header.textColor = ink.withAlphaComponent(0.45)
        headerDateLabel = header

        let clockDate = UILabel()
        clockDate.font = .systemFont(ofSize: 12, weight: .semibold)
        clockDate.textColor = ink.withAlphaComponent(0.45)
        duo.clockDateLabel = clockDate

        let days = UILabel()
        days.font = isTMinus ? .monospacedDigitSystemFont(ofSize: 180, weight: .heavy)
                             : Fonts.serif(200, tabular: true)
        days.textColor = ink
        daysNumeralLabel = days

        let daysCaption = UILabel()
        daysCaption.font = Fonts.serif(22, italic: true)
        daysCaption.textColor = ink.withAlphaComponent(0.5)
        daysCaption.numberOfLines = 2
        daysCaption.text = "days\nremaining"

        let clock = UIStackView()
        clock.axis = .horizontal
        clock.spacing = 28
        clock.alignment = .lastBaseline
        for abbreviation in ["hr", "min", "sec"] {
            let value = UILabel()
            value.font = Fonts.serif(44, tabular: true)
            value.textColor = isTMinus ? style.accent : ink
            unitValueLabels.append(value)

            let unit = UILabel()
            unit.font = Fonts.serif(14, italic: true)
            unit.textColor = ink.withAlphaComponent(0.45)
            unit.text = abbreviation

            let group = UIStackView(arrangedSubviews: [value, unit])
            group.spacing = 6
            group.alignment = .lastBaseline
            clock.addArrangedSubview(group)
        }

        let since = UILabel()
        since.font = Fonts.serif(15, italic: true)
        since.textColor = ink.withAlphaComponent(0.4)
        duo.sinceLabel = since
        duo.sinceIncludesDay = true

        [header, clockDate, days, daysCaption, clock, since].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            styleRoot.addSubview($0)
        }

        // Lower panel: ledger first so the unit rows can stop short of it.
        let span = UILabel()
        span.font = .systemFont(ofSize: 11, weight: .semibold)
        span.textColor = ink.withAlphaComponent(0.35)
        duo.spanCaption = span

        let ledger = makeDotLedger(accent: style.accent, stroke: style.ledgerStrokeColor,
                                   elapsed: style.ledgerElapsedDotColor)
        ledger.columns = 16
        ledger.cell = 19
        ledger.maxRows = 11

        addLedgerUnitRows(below: fold, gap: 41, trailing: ledger.leadingAnchor, trailingInset: 16, tight: false)

        // Wide pill: target and gear together, in reach while the phone lies flat.
        let pillHeight: CGFloat = 52
        let pill = UIControl()
        pill.backgroundColor = ink.withAlphaComponent(0.06)
        pill.layer.borderWidth = 0.5
        pill.layer.borderColor = ink.withAlphaComponent(0.1).cgColor
        pill.layer.cornerRadius = pillHeight / 2
        pill.accessibilityTraits = .button
        pill.addTarget(self, action: #selector(openSettings), for: .touchUpInside)

        let pillLabel = UILabel()
        pillLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        pillLabel.textColor = ink
        pillLabel.adjustsFontSizeToFitWidth = true
        pillLabel.minimumScaleFactor = 0.8
        duo.pillLabel = pillLabel

        let gear = UIImageView(image: UIImage(systemName: "gearshape",
                                              withConfiguration: UIImage.SymbolConfiguration(pointSize: 17)))
        gear.tintColor = ink.withAlphaComponent(0.55)

        [pillLabel, gear].forEach {
            $0.isUserInteractionEnabled = false
            $0.translatesAutoresizingMaskIntoConstraints = false
            pill.addSubview($0)
        }
        [span, pill].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            styleRoot.addSubview($0)
        }

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: safe.topAnchor, constant: 44),
            header.leadingAnchor.constraint(equalTo: styleRoot.leadingAnchor, constant: 32),
            clockDate.firstBaselineAnchor.constraint(equalTo: header.firstBaselineAnchor),
            clockDate.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -32),

            // Baselines hang from the fold so the type clears the keep-clear band.
            days.leadingAnchor.constraint(equalTo: styleRoot.leadingAnchor, constant: 26),
            days.firstBaselineAnchor.constraint(equalTo: fold, constant: -207),
            daysCaption.leadingAnchor.constraint(equalTo: days.trailingAnchor, constant: 18),
            daysCaption.lastBaselineAnchor.constraint(equalTo: days.lastBaselineAnchor, constant: -12),
            daysCaption.trailingAnchor.constraint(lessThanOrEqualTo: safe.trailingAnchor, constant: -16),

            clock.leadingAnchor.constraint(equalTo: styleRoot.leadingAnchor, constant: 32),
            clock.firstBaselineAnchor.constraint(equalTo: fold, constant: -105),
            since.leadingAnchor.constraint(equalTo: styleRoot.leadingAnchor, constant: 32),
            since.trailingAnchor.constraint(lessThanOrEqualTo: safe.trailingAnchor, constant: -16),
            since.firstBaselineAnchor.constraint(equalTo: fold, constant: -62),

            span.leadingAnchor.constraint(equalTo: ledger.leadingAnchor),
            span.topAnchor.constraint(equalTo: fold, constant: 41),
            ledger.leadingAnchor.constraint(equalTo: styleRoot.leadingAnchor, constant: 280),
            ledger.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -24),
            ledger.topAnchor.constraint(equalTo: fold, constant: 69),

            pill.leadingAnchor.constraint(equalTo: styleRoot.leadingAnchor, constant: 32),
            pill.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -32),
            pill.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -44),
            pill.heightAnchor.constraint(equalToConstant: pillHeight),
            pillLabel.leadingAnchor.constraint(equalTo: pill.leadingAnchor, constant: 22),
            pillLabel.centerYAnchor.constraint(equalTo: pill.centerYAnchor),
            pillLabel.trailingAnchor.constraint(lessThanOrEqualTo: gear.leadingAnchor, constant: -12),
            gear.trailingAnchor.constraint(equalTo: pill.trailingAnchor, constant: -22),
            gear.centerYAnchor.constraint(equalTo: pill.centerYAnchor)
        ])
    }

    // MARK: - Per-second updates

    /// Fills in the views only the foldable layouts have.
    func refreshDuo(totalDays: Int, wholeDays: Int, dayFraction: CGFloat) {
        guard !layout.isCompact else { return }
        let total = max(totalDays, 1)
        let todayIndex = min(max(total - wholeDays, 0), total - 1)   // same slot the ledger marks as today
        let spent = todayIndex
        let dayNumber = todayIndex + 1

        duo.todayGauge?.fraction = dayFraction
        duo.todayCaption?.setText("TODAY · DAY \(dayNumber) OF \(total)", kern: 2)
        duo.spanCaption?.setText("\(total) DAYS · \(spent) SPENT", kern: 2)
        duo.legendTodayLabel?.text = "today, \(Int((dayFraction * 100).rounded()))% left"

        var since = "since \(longDateFormatter.string(from: startDate))"
        if duo.sinceIncludesDay { since += " · day \(dayNumber) of \(total)" }
        duo.sinceLabel?.text = since

        if let months = duo.monthIndex {
            months.start = startDate
            months.total = total
        }
        let started = DuoFormat.monthDay.string(from: startDate)
        for (label, value) in zip(duo.metaValueLabels, [started, "\(spent) days", "\(wholeDays) days"]) {
            label.text = value
        }

        duo.clockDateLabel?.setText(DuoFormat.weekday.string(from: Date()).uppercased(), kern: 2.5)
        if let pill = duo.pillLabel {
            var target = shortDateFormatter.string(from: countdownDate)
            if !isMidnight(countdownDate) { target += " at " + timeFormatter.string(from: countdownDate) }
            pill.text = "Change target · " + target
        }
    }

    // MARK: - Settings gear and panel

    /// Wherever the system shows a vertical bar (both Duo displays), the gear
    /// is a bar item it hosts there, under the status items. Unfolded it
    /// slides the settings out as a panel over the right page instead of a
    /// sheet that would straddle the fold. Without the bar it stays in the header.
    var gearInSystemBar: Bool {
        // Table-top keeps its gear in the pill, within reach while flat.
        guard #available(iOS 27.1, *), layout != .tabletop, navigationController != nil else { return false }
        return traitCollection.verticalBarEdge != .unspecified
    }

    /// Adds or removes the bar item and shows the (transparent) navigation
    /// bar only while it has the gear to hand to the vertical bar.
    func updateSystemBarGear() {
        guard let nav = navigationController else { return }
        if gearInSystemBar, #available(iOS 27.1, *) {
            let gear = systemBarGear ?? UIBarButtonItem(image: nil, style: .plain,
                                                        target: self, action: #selector(openSettings))
            gear.axisBehavior = .verticalPreferred
            systemBarGear = gear
            navigationItem.rightBarButtonItems = [gear]
            setGearOpen(settingsPanel != nil)
            nav.setNavigationBarHidden(false, animated: false)
        } else {
            navigationItem.rightBarButtonItems = nil
            nav.setNavigationBarHidden(true, animated: false)
        }
    }

    /// The gear turns into a close button while the panel is out.
    func setGearOpen(_ open: Bool) {
        let image = UIImage(systemName: open ? "xmark" : "gearshape",
                            withConfiguration: UIImage.SymbolConfiguration(pointSize: 17))
        let label = open ? "Close settings" : "Settings"
        systemBarGear?.image = image
        systemBarGear?.accessibilityLabel = label
        if layout == .spread, let header = duo.headerGear {
            header.setImage(image, for: .normal)
            header.accessibilityLabel = label
        }
    }

    func toggleSettingsPanel(animated: Bool) {
        if settingsPanel == nil {
            openSettingsPanel(animated: animated)
        } else {
            closeSettingsPanel(animated: animated)
        }
    }

    func openSettingsPanel(animated: Bool) {
        guard settingsPanel == nil, layout == .spread else { return }
        let panel = SettingsSheetViewController(currentDate: countdownDate, embedded: true)
        panel.delegate = self
        settingsPanel = panel
        setGearOpen(true)

        // From the fold to the vertical bar; the container survives style rebuilds
        // because it sits on `view`, above `styleRoot`.
        panelContainer.clipsToBounds = true
        panelContainer.translatesAutoresizingMaskIntoConstraints = false
        if panelContainer.superview == nil {
            view.addSubview(panelContainer)
            NSLayoutConstraint.activate([
                panelContainer.leadingAnchor.constraint(equalTo: view.centerXAnchor),
                panelContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                // Without a vertical bar the gear is in the header, so the
                // panel starts below it to keep it reachable as the close button.
                gearInSystemBar
                    ? panelContainer.topAnchor.constraint(equalTo: view.topAnchor)
                    : panelContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 96),
                panelContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }

        addChild(panel)
        panel.view.translatesAutoresizingMaskIntoConstraints = false
        panelContainer.addSubview(panel.view)
        NSLayoutConstraint.activate([
            panel.view.leadingAnchor.constraint(equalTo: panelContainer.leadingAnchor),
            panel.view.trailingAnchor.constraint(equalTo: panelContainer.trailingAnchor),
            panel.view.topAnchor.constraint(equalTo: panelContainer.topAnchor),
            panel.view.bottomAnchor.constraint(equalTo: panelContainer.bottomAnchor)
        ])
        panel.didMove(toParent: self)
        view.layoutIfNeeded()

        guard animated, !UIAccessibility.isReduceMotionEnabled else { return }
        panel.view.transform = CGAffineTransform(translationX: panelContainer.bounds.width, y: 0)
        UIView.animate(withDuration: 0.45, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState]) {
            panel.view.transform = .identity
        }
    }

    func closeSettingsPanel(animated: Bool) {
        guard let panel = settingsPanel else { return }
        settingsPanel = nil
        setGearOpen(false)

        let finish = { [weak self] in
            panel.willMove(toParent: nil)
            panel.view.removeFromSuperview()
            panel.removeFromParent()
            // A panel reopened mid-slide keeps the container.
            if let self, self.settingsPanel == nil { self.panelContainer.removeFromSuperview() }
        }
        guard animated, !UIAccessibility.isReduceMotionEnabled else { finish(); return }
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
            panel.view.transform = CGAffineTransform(translationX: self.panelContainer.bounds.width, y: 0)
        }, completion: { _ in finish() })
    }

    // MARK: - Screenshot hook

    /// The simulator cannot unfold a Duo, so the inner-display layouts are
    /// checked by rendering them offscreen at the inner display's size
    /// (SIMCTL_CHILD_RENDER_DUO=1). PNGs land in the app's Documents folder.
    func renderDuoSnapshotsIfRequested() {
        guard ProcessInfo.processInfo.environment["RENDER_DUO"] != nil else { return }
        let inner = CGSize(width: 951, height: 669)
        let innerInsets = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 84)
        let tabletop = CGSize(width: 669, height: 951)
        let tabletopInsets = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 84)
        var cases: [(name: String, style: VisualStyle, layout: CountdownLayout, size: CGSize, insets: UIEdgeInsets, panel: Bool)] = []
        for style in VisualStyle.allCases {
            cases.append(("spread-\(style.rawValue)", style, .spread, inner, innerInsets, false))
            cases.append(("tabletop-\(style.rawValue)", style, .tabletop, tabletop, tabletopInsets, false))
        }
        cases.append(("spread-ledger-panel", .ledger, .spread, inner, innerInsets, true))
        cases.append(("spread-editorial-panel", .editorial, .spread, inner, innerInsets, true))

        let folder = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for item in cases {
            let vc = CountdownViewController()
            vc.forcedLayout = item.layout
            vc.loadViewIfNeeded()
            vc.timer?.invalidate()
            vc.view.frame = CGRect(origin: .zero, size: item.size)
            vc.additionalSafeAreaInsets = item.insets
            vc.style = item.style
            vc.buildInterface()
            vc.view.layoutIfNeeded()
            vc.refresh(animateRollovers: false)
            if item.panel { vc.openSettingsPanel(animated: false) }
            vc.view.layoutIfNeeded()
            vc.view.layoutIfNeeded()

            func display(_ layer: CALayer) {
                layer.displayIfNeeded()
                layer.sublayers?.forEach(display)
            }
            display(vc.view.layer)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 2
            let image = UIGraphicsImageRenderer(size: item.size, format: format).image { context in
                vc.view.layer.render(in: context.cgContext)
            }
            try? image.pngData()?.write(to: folder.appendingPathComponent("duo-\(item.name).png"))
            vc.closeSettingsPanel(animated: false)
        }
        print("RENDER_DUO wrote \(cases.count) images to \(folder.path)")
    }
}

private enum DuoFormat {
    static let monthDay: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()
    static let weekday: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE MMM d"
        return f
    }()
}
