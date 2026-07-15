//
//  SettingsSheetViewController.swift
//  Countdown
//
//  The unified settings sheet: style picker (three preview cards), the
//  target-date wheels and animation settings, all in
//  one UISheetPresentationController bottom sheet. Replaces the old gear
//  menu and the inline bottom date picker.
//

import UIKit

protocol SettingsSheetDelegate: AnyObject {
    func settingsSheet(_ sheet: SettingsSheetViewController, didSelect style: VisualStyle)
    func settingsSheet(_ sheet: SettingsSheetViewController, didPick date: Date)
    /// Fired when the refill style changes so the host can replay it live on
    /// the rings behind the sheet — a picker preview.
    func settingsSheetDidChangeRefillStyle(_ sheet: SettingsSheetViewController)
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

    // The two animation pickers: whole-row buttons whose UIMenu carries the
    // choices. Kept as references so a selection can rebuild the menu (to move
    // the checkmark) and refresh the value label.
    private let refillRow = UIButton(type: .system)
    private let refillValue = UILabel()
    private let tickPassRow = UIButton(type: .system)
    private let tickPassValue = UILabel()

    init(currentDate: Date) {
        initialDate = currentDate
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.background
        overrideUserInterfaceStyle = .dark

        let scroll = UIScrollView()
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

        // Title row
        let title = UILabel()
        title.text = "Countdown"
        title.font = .systemFont(ofSize: 19, weight: .semibold)
        title.textColor = Palette.primaryText

        let done = UIButton(type: .system)
        done.setTitle("Done", for: .normal)
        done.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        done.setTitleColor(Palette.primaryText, for: .normal)
        done.addTarget(self, action: #selector(dismissSheet), for: .touchUpInside)

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

        // Two tappable pickers: how rings refill, and how each second's tick
        // exits. Each row opens a UIMenu of the style choices.
        let animationCaption = sectionCaption("ANIMATION")
        configurePickerRow(refillRow, title: "Refill animation", value: refillValue)
        configurePickerRow(tickPassRow, title: "Second tick", value: tickPassValue)
        refreshAnimationMenus()
        let animationRows = UIStackView(arrangedSubviews: [refillRow, tickPassRow])
        animationRows.axis = .vertical
        animationRows.spacing = 1 / UIScreen.main.scale
        animationRows.backgroundColor = Palette.border
        animationRows.layer.cornerRadius = 12
        animationRows.layer.borderWidth = 1
        animationRows.layer.borderColor = Palette.border.cgColor
        animationRows.layer.masksToBounds = true

        [title, done, styleCaption, cardsRow, dateCaption, picker, animationCaption, animationRows].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview($0)
        }

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: content.topAnchor, constant: 26),
            title.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            done.centerYAnchor.constraint(equalTo: title.centerYAnchor),
            done.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            styleCaption.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 24),
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

    private func sectionCaption(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = Palette.tertiaryText
        label.setText(text, kern: 1.5)
        return label
    }

    /// Lays out a whole-row picker button: title on the left, current value +
    /// a chevron on the right. The menu is attached later in
    /// `refreshAnimationMenus()`.
    private func configurePickerRow(_ row: UIButton, title: String, value: UILabel) {
        row.backgroundColor = Palette.surface
        row.showsMenuAsPrimaryAction = true      // one tap opens the menu, no drag

        let labelView = UILabel()
        labelView.text = title
        labelView.font = .systemFont(ofSize: 14)
        labelView.textColor = Palette.secondaryText

        value.font = .systemFont(ofSize: 14, weight: .medium)
        value.textColor = Palette.primaryText
        value.textAlignment = .right

        let chevron = UIImageView(image: UIImage(systemName: "chevron.up.chevron.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 11, weight: .semibold)))
        chevron.tintColor = Palette.tertiaryText

        [labelView, value, chevron].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.isUserInteractionEnabled = false      // let taps fall through to the button
            row.addSubview($0)
        }
        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: row.topAnchor, constant: 14),
            labelView.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -14),
            labelView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            chevron.centerYAnchor.constraint(equalTo: labelView.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            value.centerYAnchor.constraint(equalTo: labelView.centerYAnchor),
            value.trailingAnchor.constraint(equalTo: chevron.leadingAnchor, constant: -8)
        ])
    }

    /// (Re)builds both menus so the checkmark tracks the current selection, and
    /// updates the value labels. Called on load and after every pick.
    private func refreshAnimationMenus() {
        let refill = DialAnimationSettings.refillStyle
        refillValue.text = refill.title
        refillRow.menu = UIMenu(children: RefillStyle.allCases.map { style in
            UIAction(title: style.title, state: style == refill ? .on : .off) { [weak self] _ in
                guard let self else { return }
                DialAnimationSettings.refillStyle = style
                self.refreshAnimationMenus()
                self.delegate?.settingsSheetDidChangeRefillStyle(self)   // live preview
            }
        })

        let tickPass = DialAnimationSettings.tickPassStyle
        tickPassValue.text = tickPass.title
        tickPassRow.menu = UIMenu(children: TickPassStyle.allCases.map { style in
            UIAction(title: style.title, state: style == tickPass ? .on : .off) { [weak self] _ in
                guard let self else { return }
                DialAnimationSettings.tickPassStyle = style
                self.refreshAnimationMenus()
            }
        })
    }

    private func refreshSelection() {
        let current = VisualStyle.saved
        cards.forEach { $0.isChosen = $0.style == current }
    }

    @objc private func cardTapped(_ card: StyleCardView) {
        guard card.style != VisualStyle.saved else { return }
        delegate?.settingsSheet(self, didSelect: card.style)   // applies instantly behind the sheet
        refreshSelection()
    }

    @objc private func dateChanged(_ picker: UIDatePicker) {
        delegate?.settingsSheet(self, didPick: picker.date)
    }

    @objc private func dismissSheet() { dismiss(animated: true) }
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
