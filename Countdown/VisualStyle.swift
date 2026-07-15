//
//  VisualStyle.swift
//  Countdown
//
//  The three switchable visual styles and their design tokens (palettes,
//  fonts). One countdown screen renders in one of these; only palette,
//  layout and typography differ — date model, tick geometry and the volley
//  refill animation are shared.
//

import UIKit

enum VisualStyle: String, CaseIterable {
    case ledger, editorial, tminus

    /// The persisted, app-wide style.
    static var saved: VisualStyle {
        get { VisualStyle(rawValue: UserDefaults.standard.string(forKey: "visualStyle") ?? "") ?? .ledger }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "visualStyle") }
    }

    var title: String {
        switch self {
        case .ledger:    return "Ledger"
        case .editorial: return "Editorial"
        case .tminus:    return "T-Minus"
        }
    }

    // MARK: - Palette

    var background: UIColor {
        switch self {
        case .ledger:    return UIColor(hex: 0x212836)
        case .editorial: return UIColor(hex: 0xF5F2EC)
        case .tminus:    return UIColor(hex: 0x14161B)
        }
    }

    var foreground: UIColor {
        switch self {
        case .ledger, .tminus: return .white
        case .editorial:       return UIColor(hex: 0x1E1D1B)
        }
    }

    var accent: UIColor {
        switch self {
        case .ledger:    return UIColor(hex: 0xBFE8FB)
        case .editorial: return UIColor(hex: 0x4C6CA8)
        case .tminus:    return UIColor(hex: 0xFF7A59)
        }
    }

    /// Filled-tick color per concentric ring, outer→inner (seconds, minutes,
    /// hours). Only Editorial and T-Minus render a `ConcentricDialView`;
    /// Ledger draws single-ring `TickDialView`s whose color is
    /// `TickDialView.filledColor` (defaulting to `ledgerFilled`), so its case
    /// here is never read.
    var concentricFilledColors: [UIColor] {
        switch self {
        case .ledger:
            assertionFailure("concentricFilledColors is unused by Ledger — edit TickDialView.filledColor instead")
            let c = VisualStyle.ledgerFilled
            return [c, c, c]
        case .editorial:
            let ink = foreground
            return [ink.withAlphaComponent(0.75), ink.withAlphaComponent(0.50), ink.withAlphaComponent(0.30)]
        case .tminus:
            return [UIColor(white: 1, alpha: 0.30), UIColor(white: 1, alpha: 0.22), UIColor(white: 1, alpha: 0.14)]
        }
    }

    var trackColor: UIColor {
        switch self {
        case .ledger:    return UIColor(white: 0.592, alpha: 0.14)
        case .editorial: return foreground.withAlphaComponent(0.09)
        case .tminus:    return UIColor(white: 1, alpha: 0.05)
        }
    }

    /// Filled elapsed-day discs in the dot ledger: the style's foreground at a
    /// reduced alpha so passed days read as spent-but-present (per the ledger
    /// handoff). Distinct per style — darker ink reads at a higher alpha than
    /// white-on-dark.
    var ledgerElapsedDotColor: UIColor {
        switch self {
        case .ledger:    return UIColor(white: 1, alpha: 0.5)
        case .editorial: return foreground.withAlphaComponent(0.6)
        case .tminus:    return UIColor(white: 1, alpha: 0.35)
        }
    }

    /// Ledger's dial fill — rgba(151,151,151,0.9), carried over from the
    /// original dials.
    static let ledgerFilled = UIColor(white: 0.592, alpha: 0.9)

    var isDark: Bool { self != .editorial }
}

// MARK: - Fonts

enum Fonts {
    /// New York on iOS (the HTML designs use Georgia as the web stand-in).
    static func serif(_ size: CGFloat, weight: UIFont.Weight = .regular,
                      italic: Bool = false, tabular: Bool = false) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        var descriptor = base.fontDescriptor.withDesign(.serif) ?? base.fontDescriptor
        if italic, let d = descriptor.withSymbolicTraits(descriptor.symbolicTraits.union(.traitItalic)) {
            descriptor = d
        }
        if tabular {
            descriptor = descriptor.addingAttributes([.featureSettings: [
                [UIFontDescriptor.FeatureKey.type: kNumberSpacingType,
                 UIFontDescriptor.FeatureKey.selector: kMonospacedNumbersSelector]
            ]])
        }
        return UIFont(descriptor: descriptor, size: size)
    }
}

// MARK: - Helpers

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}

extension UILabel {
    /// Sets text with letter-spacing while keeping the label's font/color.
    func setText(_ text: String, kern: CGFloat) {
        attributedText = NSAttributedString(string: text, attributes: [.kern: kern])
    }
}
