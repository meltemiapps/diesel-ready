import SwiftUI
import UIKit

/// Design tokens for Diesel Ready.
///
/// Light values are the approved palette from the brief. Dark values are chosen
/// to keep the same roles with equivalent (WCAG AA, 4.5:1 or better) contrast.
enum Theme {

    // MARK: Colours

    enum Palette {
        /// Hero surfaces (headers, disclaimer backdrop).
        static let navy = Color(light: 0x0F2A3D, dark: 0x0F2A3D)
        static let deepBlue = Color(light: 0x163A52, dark: 0x163A52)
        /// Primary buttons. Always paired with `onAccent` text, never white.
        static let accent = Color(light: 0xF2A33A, dark: 0xF2A33A)
        static let onAccent = Color(light: 0x0F2A3D, dark: 0x0F2A3D)
        static let link = Color(light: 0x1F4E6B, dark: 0x8EC3E3)
        static let ink = Color(light: 0x13212B, dark: 0xE8EEF2)
        static let secondaryText = Color(light: 0x4A5A66, dark: 0xA9B7C1)
        static let background = Color(light: 0xF4F6F7, dark: 0x0B161E)
        static let surface = Color(light: 0xFFFFFF, dark: 0x15242F)
        static let divider = Color(light: 0xDCE3E8, dark: 0x2A3D4B)

        static let success = Color(light: 0x1E7A4C, dark: 0x7FD6A4)
        static let successBackground = Color(light: 0xE6F4EC, dark: 0x12301F)
        static let error = Color(light: 0xB3261E, dark: 0xFF9A90)
        static let errorBackground = Color(light: 0xFBE9E7, dark: 0x3A1512)
        static let caution = Color(light: 0x6B3A00, dark: 0xFFCB80)
        static let cautionBackground = Color(light: 0xFFF4E3, dark: 0x33240D)

        /// Text and icons placed on navy hero surfaces.
        static let onHero = Color(light: 0xFFFFFF, dark: 0xFFFFFF)
        static let onHeroSecondary = Color(light: 0xC9D6DF, dark: 0xC9D6DF)

        /// Tab bar and control tint. Amber fails contrast on light backgrounds,
        /// so light mode uses link blue and dark mode uses amber.
        static let tint = Color(light: 0x1F4E6B, dark: 0xF2A33A)

        /// Selected filter chips: navy in light mode, amber in dark mode, where
        /// navy would barely stand out from the background.
        static let selectedChip = Color(light: 0x0F2A3D, dark: 0xF2A33A)
        static let onSelectedChip = Color(light: 0xFFFFFF, dark: 0x0F2A3D)
    }

    // MARK: Shape and spacing

    enum Radius {
        static let card: CGFloat = 18
        static let button: CGFloat = 14
        static let hero: CGFloat = 22
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 24
    }

    /// Minimum touch target from the Human Interface Guidelines.
    static let minTouchTarget: CGFloat = 44
}

// MARK: - Typography

extension Font {
    /// Bold rounded heading styles. All are text-style based, so they scale with Dynamic Type.
    static let heroTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let screenTitle = Font.system(.title, design: .rounded).weight(.bold)
    static let sectionTitle = Font.system(.title3, design: .rounded).weight(.bold)
    static let cardTitle = Font.system(.headline, design: .rounded).weight(.bold)
}

// MARK: - Helpers

extension Color {
    /// A colour that switches between two sRGB hex values with the interface style.
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { traits in
            UIColor(hex: traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
