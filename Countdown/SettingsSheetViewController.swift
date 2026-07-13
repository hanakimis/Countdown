//
//  SettingsSheetViewController.swift
//  Countdown
//
//  The unified settings sheet: style picker (three preview cards), the
//  target-date wheels and the (informational) refill-animation row, all in
//  one UISheetPresentationController bottom sheet. Replaces the old gear
//  menu and the inline bottom date picker.
//

import UIKit

protocol SettingsSheetDelegate: AnyObject {
    func settingsSheet(_ sheet: SettingsSheetViewController, didSelect style: VisualStyle)
    func settingsSheet(_ sheet: SettingsSheetViewController, didPick date: Date)
}

final class SettingsSheetViewController: UIViewController {

    weak var delegate: SettingsSheetDelegate?

    private let initialDate: Date
    private var cards: [StyleCardView] = []
    private let sheetAccent = UIColor(hex: 0xBFE8FB)

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
        view.backgroundColor = UIColor(hex: 0x2A3140)
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
        title.textColor = .white

        let done = UIButton(type: .system)
        done.setTitle("Done", for: .normal)
        done.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        done.setTitleColor(sheetAccent, for: .normal)
        done.addTarget(self, action: #selector(dismissSheet), for: .touchUpInside)

        // STYLE section
        let styleCaption = sectionCaption("STYLE")

        let cardsRow = UIStackView()
        cardsRow.axis = .horizontal
        cardsRow.distribution = .fillEqually
        cardsRow.spacing = 10
        for style in VisualStyle.allCases {
            let card = StyleCardView(style: style, accent: sheetAccent)
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

        // Refill animation row — informational; the volley is the single
        // shipped animation (the old 6-style list is retired).
        let refillRow = UIView()
        refillRow.backgroundColor = UIColor(white: 1, alpha: 0.05)
        refillRow.layer.cornerRadius = 12
        refillRow.layer.borderWidth = 1
        refillRow.layer.borderColor = UIColor(white: 1, alpha: 0.08).cgColor

        let refillLabel = UILabel()
        refillLabel.text = "Refill animation"
        refillLabel.font = .systemFont(ofSize: 14)
        refillLabel.textColor = UIColor(white: 1, alpha: 0.6)

        let refillValue = UILabel()
        refillValue.text = "Launch volley"
        refillValue.font = .systemFont(ofSize: 14, weight: .medium)
        refillValue.textColor = .white

        [title, done, styleCaption, cardsRow, dateCaption, picker, refillRow].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview($0)
        }
        [refillLabel, refillValue].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            refillRow.addSubview($0)
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

            refillRow.topAnchor.constraint(equalTo: picker.bottomAnchor, constant: 14),
            refillRow.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            refillRow.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            refillRow.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -28),

            refillLabel.topAnchor.constraint(equalTo: refillRow.topAnchor, constant: 14),
            refillLabel.bottomAnchor.constraint(equalTo: refillRow.bottomAnchor, constant: -14),
            refillLabel.leadingAnchor.constraint(equalTo: refillRow.leadingAnchor, constant: 16),
            refillValue.centerYAnchor.constraint(equalTo: refillLabel.centerYAnchor),
            refillValue.trailingAnchor.constraint(equalTo: refillRow.trailingAnchor, constant: -16)
        ])
    }

    private func sectionCaption(_ text: String) -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor(white: 1, alpha: 0.4)
        label.setText(text, kern: 1.5)
        return label
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
    private let accent: UIColor
    private let nameLabel = UILabel()
    private let thumb: StyleThumbView

    var isChosen: Bool = false { didSet { refresh() } }

    init(style: VisualStyle, accent: UIColor) {
        self.style = style
        self.accent = accent
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
            backgroundColor = accent.withAlphaComponent(0.1)
            layer.borderWidth = 1.5
            layer.borderColor = accent.cgColor
            nameLabel.textColor = accent
            nameLabel.text = "\(style.title) ✓"
        } else {
            backgroundColor = UIColor(white: 1, alpha: 0.05)
            layer.borderWidth = 1
            layer.borderColor = UIColor(white: 1, alpha: 0.1).cgColor
            nameLabel.textColor = UIColor(white: 1, alpha: 0.7)
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
