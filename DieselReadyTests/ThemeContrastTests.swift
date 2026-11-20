import SwiftUI
import Testing
import UIKit
@testable import DieselReady

/// Every text colour the app draws, on every background it is drawn on, meets
/// WCAG AA (4.5:1) in both light and dark mode.
@Suite("Design system contrast")
struct ThemeContrastTests {
    typealias P = Theme.Palette

    /// (text, background, description)
    static let pairs: [(Color, Color, String)] = [
        (P.ink, P.background, "ink on background"),
        (P.ink, P.surface, "ink on surface"),
        (P.secondaryText, P.background, "secondary on background"),
        (P.secondaryText, P.surface, "secondary on surface"),
        (P.link, P.surface, "link on surface"),
        (P.link, P.background, "link on background"),
        (P.onAccent, P.accent, "button text on amber"),
        (P.onHero, P.navy, "white on navy hero"),
        (P.onHeroSecondary, P.navy, "secondary on navy hero"),
        (P.onHero, P.deepBlue, "white on deep blue badge"),
        (P.success, P.successBackground, "success callout"),
        (P.error, P.errorBackground, "error callout"),
        (P.caution, P.cautionBackground, "caution callout"),
        (P.success, P.surface, "success text on surface"),
        (P.ink, P.successBackground, "option text on correct answer"),
        (P.ink, P.errorBackground, "option text on wrong answer"),
        (P.onSelectedChip, P.selectedChip, "selected chip"),
        (P.secondaryText, P.divider, "disabled button text"),
        (P.error, P.surface, "stop card headings on surface"),
        (P.link, P.background, "observe badge"),
        (P.caution, P.cautionBackground, "owner badge"),
        (P.error, P.errorBackground, "engineer badge"),
    ]

    @Test("WCAG AA contrast in light and dark mode", arguments: [UIUserInterfaceStyle.light, .dark])
    func contrast(style: UIUserInterfaceStyle) {
        let traits = UITraitCollection(userInterfaceStyle: style)
        for (text, background, name) in Self.pairs {
            let ratio = Self.ratio(UIColor(text).resolvedColor(with: traits),
                                   UIColor(background).resolvedColor(with: traits))
            #expect(ratio >= 4.5, "\(name) is \(String(format: "%.2f", ratio)):1 in \(style == .dark ? "dark" : "light") mode")
        }
    }

    static func ratio(_ a: UIColor, _ b: UIColor) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    static func luminance(_ color: UIColor) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        func channel(_ c: CGFloat) -> Double {
            let c = Double(c)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }
}
