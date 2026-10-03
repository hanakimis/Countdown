//
//  SettingsSheetViewController.swift
//  Countdown
//
//  The unified settings sheet: style picker (three preview cards), the
//  target-date wheels and animation settings (each with a live preview tile
//  and an inline wheel), all in one UISheetPresentationController
//  bottom sheet. Replaces the old gear
//  menu and the inline bottom date picker.
//

import UIKit

protocol SettingsSheetDelegate: AnyObject {
    func settingsSheet(_ sheet: SettingsSheetViewController, didSelect style: VisualStyle)
    func settingsSheet(_ sheet: SettingsSheetViewController, didPick date: Date)
    /// Fired when the refill style changes so the host can replay it live on
    /// the rings behind the sheet — a picker preview.
    func settingsSheetDidChangeRefillStyle(_ sheet: SettingsSheetViewController)
    /// Fired when the ledger load style changes so the host can replay it live
    /// on the dot grid behind the sheet.
    func settingsSheetDidChangeLedgerLoadStyle(_ sheet: SettingsSheetViewController)
}

final class SettingsSheetViewController: UIViewController {

    /// A fixed, achromatic palette keeps the settings chrome independent of
    /// whichever countdown style is visible behind it. Theme colors belong
    /// only inside the three previews.
    private enum Palette {
        static let background = UIColor(hex: 0x1C1C1E)
        static let surface = UIColor(hex: 0x2C2C2E)
        static let primaryText = UIColor.white
        static let secondaryText = UIColor(white: 1, alpha: 0.64)
        static let tertiaryText = UIColor(white: 1, alpha: 0.42)
        static let border = UIColor(white: 1, alpha: 0.12)
        static let selectedBorder = UIColor(white: 1, alpha: 0.82)
        static let selectedFill = UIColor(white: 1, alpha: 0.08)
    }

    weak var delegate: SettingsSheetDelegate?

    private let initialDate: Date
    private var cards: [StyleCardView] = []

    private let scroll = UIScrollView()

    /// Identifier for the content-sized detent that opens the sheet tall enough
    /// to reveal every section — style, date, and animation — without a drag.
    private static let fitDetentID = UISheetPresentationController.Detent.Identifier("fitContent")

    /// Height the fit detent resolves to. Seeded with a sensible default, then
    /// refined from the real laid-out content in `viewDidLayoutSubviews`.
    private var contentHeight: CGFloat = 560

    // Animation previews: a miniature dial / dot grid per setting, drawn in the
    // current visual style's colors so a pick plays here exactly as it will on
    // the countdown. (The real dot grid sits behind the sheet, out of view.)
    private let refillPreview = TickDialView()
    private let tickPassPreview = TickDialView()
    private let ledgerPreview = DotLedgerView()
    private var animationCards: [AnimationPickerCard] = []
    /// Drives the tick-pass preview like a seconds ring while the sheet is up.
    private var tickTimer: Timer?
    private var didPlayIntro = false

    init(currentDate: Date) {
        initialDate = currentDate
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            if #available(iOS 16.0, *) {
                // A content-sized detent so the sheet opens tall enough to show
                // the animation pickers without dragging. `.large()` stays
                // available for anyone who wants the full-height sheet.
                let fit = UISheetPresentationController.Detent.custom(
                    identifier: Self.fitDetentID
                ) { [weak self] context in
                    let target = self?.contentHeight ?? context.maximumDetentValue
                    return min(target, context.maximumDetentValue)
                }
                sheet.detents = [fit, .large()]
                sheet.selectedDetentIdentifier = Self.fitDetentID
            } else {
                // iOS 15 has no custom detent; open full-height so every section
                // is visible without a drag.
                sheet.detents = [.large()]
            }
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.background
        overrideUserInterfaceStyle = .dark

        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])

        // STYLE section
        let styleCaption = sectionCaption("STYLE")

        let cardsRow = UIStackView()
        cardsRow.axis = .horizontal
        cardsRow.distribution = .fillEqually
        cardsRow.spacing = 10
        for style in VisualStyle.allCases {
            let card = StyleCardView(
                style: style,
                surface: Palette.surface,
                textColor: Palette.secondaryText,
                borderColor: Palette.border,
                selectedFill: Palette.selectedFill,
                selectedTextColor: Palette.primaryText,
                selectedBorderColor: Palette.selectedBorder
            )
            card.addTarget(self, action: #selector(cardTapped(_:)), for: .touchUpInside)
            cards.append(card)
            cardsRow.addArrangedSubview(card)
        }
        refreshSelection()

        // DATE & TIME section
        let dateCaption = sectionCaption("DATE & TIME")

        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .wheels
        // Floor at today for new/future targets, but never above the saved
        // date — otherwise an already-elapsed target would be silently clamped
        // to today and the first wheel touch would overwrite it with today.
        picker.minimumDate = min(Date(), initialDate)
        picker.date = initialDate
        picker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)

        // One card per animation setting: live preview + inline wheel. Landing
        // on an option saves it and plays it in the preview straight away.
        let animationCaption = sectionCaption("ANIMATION")
        configurePreviews()

        let refillCard = animationCard(
            title: "Refill", current: DialAnimationSettings.refillStyle, label: \.title,
            preview: refillPreview,
            select: { [weak self] style in
                guard let self else { return }
                DialAnimationSettings.refillStyle = style
                self.delegate?.settingsSheetDidChangeRefillStyle(self)   // also replay the rings behind the sheet
            },
            replay: { [weak self] in self?.refillPreview.refill() })

        let tickPassCard = animationCard(
            title: "Second tick", current: DialAnimationSettings.tickPassStyle, label: \.title,
            preview: tickPassPreview,
            select: { DialAnimationSettings.tickPassStyle = $0 },
            replay: { [weak self] in self?.tickPreviewNow() })

        let ledgerCard = animationCard(
            title: "Dot ledger", current: DialAnimationSettings.ledgerLoadStyle, label: \.title,
            preview: ledgerPreview,
            select: { [weak self] style in
                guard let self else { return }
                DialAnimationSettings.ledgerLoadStyle = style
                self.delegate?.settingsSheetDidChangeLedgerLoadStyle(self)
            },
            replay: { [weak self] in self?.ledgerPreview.replayLoad() })

        animationCards = [refillCard, tickPassCard, ledgerCard]
        applyPreviewStyle(VisualStyle.saved)
        let animationRows = UIStackView(arrangedSubviews: animationCards)
        animationRows.axis = .vertical
        animationRows.spacing = 8

        [styleCaption, cardsRow, dateCaption, picker, animationCaption, animationRows].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview($0)
        }

        NSLayoutConstraint.activate([
            // No title/Done row: the grabber handles dismissal, so the first
            // section starts just below it and reclaims that vertical space.
            styleCaption.topAnchor.constraint(equalTo: content.topAnchor, constant: 28),
            styleCaption.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),

            cardsRow.topAnchor.constraint(equalTo: styleCaption.bottomAnchor, constant: 10),
            cardsRow.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            cardsRow.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            cardsRow.heightAnchor.constraint(equalToConstant: 118),

            dateCaption.topAnchor.constraint(equalTo: cardsRow.bottomAnchor, constant: 22),
            dateCaption.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),

            picker.topAnchor.constraint(equalTo: dateCaption.bottomAnchor, constant: 2),
            picker.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            picker.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            picker.heightAnchor.constraint(equalToConstant: 180),

            animationCaption.topAnchor.constraint(equalTo: picker.bottomAnchor, constant: 14),
            animationCaption.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),

            animationRows.topAnchor.constraint(equalTo: animationCaption.bottomAnchor, constant: 10),
            animationRows.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            animationRows.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            animationRows.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -28)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard #available(iOS 16.0, *) else { return }
        // Once Auto Layout has resolved the scroll content, size the fit detent
        // to it so the sheet rests exactly tall enough to show every section.
        // Custom detent heights exclude the bottom safe area — UIKit adds it —
        // so it isn't added here. invalidateDetents re-runs the resolver.
        let target = scroll.contentSize.height
        guard target > 0, abs(target - contentHeight) > 0.5 else { return }
        contentHeight = target
        sheetPresentationController?.animateChanges {
            sheetPresentationController?.invalidateDetents()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startTickTimer()
        // Play the selected refill once as the sheet lands (the ledger preview
        // plays its own load on first layout).
        if !didPlayIntro {
            didPlayIntro = true
            refillPreview.refill()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func sectionCaption(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = Palette.tertiaryText
        label.setText(text, kern: 1.5)
        return label
    }

    // MARK: Animation previews

    /// Builds one picker card for a `CaseIterable` animation enum. `select`
    /// persists the choice; `replay` plays it in the card's preview tile.
    private func animationCard<Option: CaseIterable & Equatable>(
        title: String,
        current: Option,
        label: (Option) -> String,
        preview: UIView,
        select: @escaping (Option) -> Void,
        replay: @escaping () -> Void
    ) -> AnimationPickerCard where Option.AllCases == [Option] {
        let options = Option.allCases
        return AnimationPickerCard(
            title: title,
            options: options.map(label),
            selectedIndex: options.firstIndex(of: current) ?? 0,
            preview: preview,
            colors: .init(surface: Palette.surface,
                          border: Palette.border,
                          title: Palette.secondaryText,
                          value: Palette.primaryText),
            onSelect: { select(options[$0]) },
            onReplay: replay)
    }

    /// Seeds the three miniature views with representative values: a ring
    /// that's mostly full, and a small grid part-way through its span.
    private func configurePreviews() {
        for dial in [refillPreview, tickPassPreview] {
            dial.total = 24
            dial.tickWidth = 2.6
            dial.tickLengthRatio = 0.3
            dial.setValue(17, animated: false)
        }
        ledgerPreview.columns = 6
        ledgerPreview.cell = 16
        ledgerPreview.setValues(total: 24, wholeDays: 15, dayFraction: 0.6, animated: false)
    }

    /// Repaints every preview tile in `style`'s palette, so the previews match
    /// the countdown currently showing behind the sheet.
    private func applyPreviewStyle(_ style: VisualStyle) {
        animationCards.forEach { $0.tile.backgroundColor = style.background }
        for dial in [refillPreview, tickPassPreview] {
            dial.filledColor = style.singleDialFilledColor
            dial.trackColor = style.trackColor
            dial.accentColor = style.accent
        }
        ledgerPreview.accentColor = style.accent
        ledgerPreview.strokeColor = style.ledgerStrokeColor
        ledgerPreview.elapsedColor = style.ledgerElapsedDotColor
    }

    /// Counts the tick-pass preview down one step, like a seconds ring. Near
    /// empty it rolls over (a refill), just as the real ring does at :00.
    private func advanceTickPreview() {
        let v = tickPassPreview.value
        tickPassPreview.setValue(v <= 4 ? 17 : v - 1, animated: true)
    }

    /// Plays a tick immediately (on pick / tap) and restarts the 1 s cadence
    /// so the next automatic tick doesn't land right on top of it.
    private func tickPreviewNow() {
        advanceTickPreview()
        startTickTimer()
    }

    private func startTickTimer() {
        tickTimer?.invalidate()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.advanceTickPreview()
        }
    }

    private func refreshSelection() {
        let current = VisualStyle.saved
        cards.forEach { $0.isChosen = $0.style == current }
    }

    @objc private func cardTapped(_ card: StyleCardView) {
        guard card.style != VisualStyle.saved else { return }
        delegate?.settingsSheet(self, didSelect: card.style)   // applies instantly behind the sheet
        refreshSelection()
        applyPreviewStyle(card.style)
    }

    @objc private func dateChanged(_ picker: UIDatePicker) {
        delegate?.settingsSheet(self, didPick: picker.date)
    }
}

// MARK: - Animation picker cards

/// One animation setting: a large live preview filling the left half, its
/// title and an inline wheel on the right — scrolled in place, like the date
/// wheels above. Landing on an option (or tapping the preview) replays it.
private final class AnimationPickerCard: UIView, UIPickerViewDataSource, UIPickerViewDelegate {

    struct Colors {
        let surface, border, title, value: UIColor
    }

    /// The preview's backdrop — painted in the current visual style by the sheet.
    let tile = UIView()

    private let options: [String]
    private let colors: Colors
    private let onSelect: (Int) -> Void
    private let onReplay: () -> Void
    private var selectedIndex: Int
    private let wheel = UIPickerView()

    init(title: String, options: [String], selectedIndex: Int, preview: UIView, colors: Colors,
         onSelect: @escaping (Int) -> Void, onReplay: @escaping () -> Void) {
        self.options = options
        self.colors = colors
        self.onSelect = onSelect
        self.onReplay = onReplay
        self.selectedIndex = selectedIndex
        super.init(frame: .zero)

        backgroundColor = colors.surface
        layer.cornerRadius = 14
        layer.borderWidth = 1
        layer.borderColor = colors.border.cgColor
        layer.masksToBounds = true

        // Preview tile — the whole tile is the replay target.
        tile.layer.cornerRadius = 10
        tile.layer.masksToBounds = true
        tile.isAccessibilityElement = true
        tile.accessibilityLabel = "\(title) preview"
        tile.accessibilityHint = "Plays the selected animation."
        tile.accessibilityTraits = .button
        tile.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tileTapped)))
        preview.isUserInteractionEnabled = false     // taps belong to the tile
        preview.translatesAutoresizingMaskIntoConstraints = false
        tile.addSubview(preview)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = colors.title
        // The wheel resists shrinking harder than a label does by default; without
        // this the title is the one that gets squeezed to zero height.
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        wheel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        wheel.dataSource = self
        wheel.delegate = self
        wheel.accessibilityLabel = title
        wheel.clipsToBounds = true                   // its 3-D rows otherwise spill over the title
        wheel.selectRow(selectedIndex, inComponent: 0, animated: false)

        [tile, titleLabel, wheel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            tile.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            tile.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            tile.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            tile.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.5, constant: -15),
            tile.heightAnchor.constraint(equalToConstant: 112),

            preview.centerXAnchor.constraint(equalTo: tile.centerXAnchor),
            preview.centerYAnchor.constraint(equalTo: tile.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: tile.topAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: tile.trailingAnchor, constant: 14),

            // ~100 pt of wheel under the title: the chosen row plus a faded
            // neighbour above and below, like the date wheels.
            wheel.leadingAnchor.constraint(equalTo: tile.trailingAnchor, constant: 4),
            wheel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            wheel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor),
            wheel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        ])

        // Dials are square and fill the tile's height; the dot grid keeps its
        // intrinsic (cell-based) size.
        if preview is TickDialView {
            NSLayoutConstraint.activate([
                preview.heightAnchor.constraint(equalTo: tile.heightAnchor, constant: -18),
                preview.widthAnchor.constraint(equalTo: preview.heightAnchor)
            ])
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Wheel

    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        options.count
    }

    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat { 30 }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int,
                    reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.text = options[row]
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = colors.value
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.8
        label.textAlignment = .left
        return label
    }

    /// Fires once the wheel settles. The wheel gives its own detent haptics,
    /// so this only persists the choice and plays it.
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row != selectedIndex {
            selectedIndex = row
            onSelect(row)
        }
        onReplay()
    }

    @objc private func tileTapped() { onReplay() }
}

// MARK: - Style cards

private final class StyleCardView: UIControl {

    let style: VisualStyle
    private let surface: UIColor
    private let textColor: UIColor
    private let borderColor: UIColor
    private let selectedFill: UIColor
    private let selectedTextColor: UIColor
    private let selectedBorderColor: UIColor
    private let nameLabel = UILabel()
    private let thumb: StyleThumbView

    var isChosen: Bool = false { didSet { refresh() } }

    init(style: VisualStyle,
         surface: UIColor,
         textColor: UIColor,
         borderColor: UIColor,
         selectedFill: UIColor,
         selectedTextColor: UIColor,
         selectedBorderColor: UIColor) {
        self.style = style
        self.surface = surface
        self.textColor = textColor
        self.borderColor = borderColor
        self.selectedFill = selectedFill
        self.selectedTextColor = selectedTextColor
        self.selectedBorderColor = selectedBorderColor
        self.thumb = StyleThumbView(style: style)
        super.init(frame: .zero)

        layer.cornerRadius = 14

        thumb.translatesAutoresizingMaskIntoConstraints = false
        thumb.isUserInteractionEnabled = false
        thumb.layer.cornerRadius = 8
        thumb.layer.masksToBounds = true
        addSubview(thumb)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.font = .systemFont(ofSize: 11.5, weight: .medium)
        nameLabel.textAlignment = .center
        addSubview(nameLabel)

        NSLayoutConstraint.activate([
            thumb.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            thumb.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            thumb.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            nameLabel.topAnchor.constraint(equalTo: thumb.bottomAnchor, constant: 7),
            nameLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func refresh() {
        if isChosen {
            backgroundColor = selectedFill
            layer.borderWidth = 1.5
            layer.borderColor = selectedBorderColor.cgColor
            nameLabel.textColor = selectedTextColor
            nameLabel.text = "\(style.title) ✓"
        } else {
            backgroundColor = surface
            layer.borderWidth = 1
            layer.borderColor = borderColor.cgColor
            nameLabel.textColor = textColor
            nameLabel.text = style.title
        }
    }
}

/// A miniature drawn preview of a style — enough to tell them apart at a
/// glance, not a live render.
private final class StyleThumbView: UIView {

    private let style: VisualStyle

    init(style: VisualStyle) {
        self.style = style
        super.init(frame: .zero)
        backgroundColor = style.background
        contentMode = .redraw
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func draw(_ rect: CGRect) {
        let ink = style.foreground
        let accent = style.accent

        func text(_ string: String, _ font: UIFont, _ color: UIColor, _ point: CGPoint) {
            (string as NSString).draw(at: point, withAttributes: [.font: font, .foregroundColor: color])
        }
        func miniRing(center: CGPoint, radius: CGFloat, ticks: Int, color: UIColor) {
            for i in 0..<ticks {
                let a = -CGFloat.pi / 2 + CGFloat(i) / CGFloat(ticks) * 2 * .pi
                let p = UIBezierPath()
                p.move(to: CGPoint(x: center.x + cos(a) * radius * 0.72, y: center.y + sin(a) * radius * 0.72))
                p.addLine(to: CGPoint(x: center.x + cos(a) * radius, y: center.y + sin(a) * radius))
                p.lineWidth = 0.8
                color.setStroke()
                p.stroke()
            }
        }

        switch style {
        case .ledger:
            for row in 0..<2 {
                let y = 10 + CGFloat(row) * 14
                miniRing(center: CGPoint(x: 14, y: y), radius: 5, ticks: 12, color: ink.withAlphaComponent(0.55))
                let bar = UIBezierPath(rect: CGRect(x: 24, y: y - 1.5, width: 16, height: 3))
                ink.withAlphaComponent(0.35).setFill()
                bar.fill()
            }
            text("64", Fonts.serif(20), ink, CGPoint(x: 8, y: rect.height - 36))
            for i in 0..<5 {
                let cx = 10 + CGFloat(i) * 9
                let cy = rect.height - 8.0
                let dot = UIBezierPath(arcCenter: CGPoint(x: cx, y: cy), radius: 2,
                                       startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                if i == 0 { accent.setFill(); dot.fill() }
                else { ink.withAlphaComponent(0.3).setStroke(); dot.lineWidth = 0.8; dot.stroke() }
            }
        case .editorial:
            let c = CGPoint(x: rect.midX, y: rect.midY - 4)
            miniRing(center: c, radius: 24, ticks: 40, color: ink.withAlphaComponent(0.6))
            miniRing(center: c, radius: 17, ticks: 30, color: ink.withAlphaComponent(0.35))
            let n = "64" as NSString
            let f = Fonts.serif(15)
            let s = n.size(withAttributes: [.font: f])
            n.draw(at: CGPoint(x: c.x - s.width / 2, y: c.y - s.height / 2),
                   withAttributes: [.font: f, .foregroundColor: ink])
        case .tminus:
            text("T-MINUS", .systemFont(ofSize: 5, weight: .bold), accent, CGPoint(x: 8, y: 8))
            text("64", .systemFont(ofSize: 24, weight: .heavy), ink, CGPoint(x: 7, y: 15))
            text("23 09 34", .systemFont(ofSize: 7, weight: .bold), accent, CGPoint(x: 8, y: rect.height - 14))
            miniRing(center: CGPoint(x: rect.maxX + 12, y: rect.midY),
                     radius: 30, ticks: 40, color: ink.withAlphaComponent(0.25))
        }
    }
}
