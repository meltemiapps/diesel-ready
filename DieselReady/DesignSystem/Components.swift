import SwiftUI

// MARK: - Buttons

/// Amber primary button with navy text, as specified in the design system.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? Theme.Palette.onAccent : Theme.Palette.secondaryText)
            .frame(maxWidth: .infinity, minHeight: Theme.minTouchTarget)
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                    .fill(isEnabled ? Theme.Palette.accent : Theme.Palette.divider)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
    }
}

/// Outlined secondary button.
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Theme.Palette.link)
            .frame(maxWidth: .infinity, minHeight: Theme.minTouchTarget)
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.vertical, Theme.Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                    .fill(Theme.Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                    .strokeBorder(Theme.Palette.divider, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.85 : 1)
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
    }
}

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

// MARK: - Cards

/// White (or dark surface) rounded card.
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .fill(Theme.Palette.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                    .strokeBorder(Theme.Palette.divider, lineWidth: 1)
            )
    }
}

extension View {
    func card() -> some View { modifier(CardModifier()) }
}

// MARK: - Badges and callouts

/// Small "Unofficial" pill shown in screen headers.
struct UnofficialBadge: View {
    var body: some View {
        Text("Unofficial")
            .font(.caption.weight(.bold))
            .textCase(.uppercase)
            .foregroundStyle(Theme.Palette.onAccent)
            .padding(.horizontal, Theme.Spacing.s)
            .padding(.vertical, Theme.Spacing.xs)
            .background(Capsule().fill(Theme.Palette.accent))
            .accessibilityLabel("Unofficial study guide")
    }
}

/// Tinted callout used for cautions, and later for quiz feedback.
struct Callout: View {
    enum Kind {
        case caution, success, error

        var foreground: Color {
            switch self {
            case .caution: Theme.Palette.caution
            case .success: Theme.Palette.success
            case .error: Theme.Palette.error
            }
        }

        var background: Color {
            switch self {
            case .caution: Theme.Palette.cautionBackground
            case .success: Theme.Palette.successBackground
            case .error: Theme.Palette.errorBackground
            }
        }

        var symbol: String {
            switch self {
            case .caution: "exclamationmark.triangle.fill"
            case .success: "checkmark.circle.fill"
            case .error: "xmark.octagon.fill"
            }
        }
    }

    let kind: Kind
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
            Image(systemName: kind.symbol)
                .accessibilityHidden(true)
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.callout)
        .foregroundStyle(kind.foreground)
        .padding(Theme.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                .fill(kind.background)
        )
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Number badges

/// A number or letter in a circle (step numbers, option letters, module
/// numbers). The circle grows with Dynamic Type and always stays round, so the
/// text is never clipped at the largest accessibility sizes.
struct NumberBadge: View {
    let text: String
    var fill: Color? = nil
    var stroke: Color? = nil
    var foreground: Color
    var font: Font = .subheadline.weight(.bold)
    private let base: CGFloat
    @ScaledMetric private var scaled: CGFloat
    /// Grows with the text, but no more than about twice its normal size.
    private var diameter: CGFloat { min(scaled, base * 1.8) }

    init(_ text: String, fill: Color? = nil, stroke: Color? = nil, foreground: Color,
         diameter: CGFloat = 28, font: Font = .subheadline.weight(.bold),
         relativeTo textStyle: Font.TextStyle = .subheadline) {
        self.text = text
        self.fill = fill
        self.stroke = stroke
        self.foreground = foreground
        self.font = font
        base = diameter
        _scaled = ScaledMetric(wrappedValue: diameter, relativeTo: textStyle)
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(foreground)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .padding(diameter * 0.12)
            .frame(width: diameter, height: diameter)
            .background {
                if let fill { Circle().fill(fill) }
                if let stroke { Circle().strokeBorder(stroke, lineWidth: 1.5) }
            }
    }
}

// MARK: - Adaptive rows

/// A list row with a leading badge, the main text and a trailing icon. At
/// accessibility text sizes the badge and icon move onto their own line above
/// the text, so the text keeps the full width instead of wrapping a word (or
/// a few letters) per line.
struct AdaptiveRow<Leading: View, Content: View, Trailing: View>: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ViewBuilder var leading: Leading
    @ViewBuilder var content: Content
    @ViewBuilder var trailing: Trailing

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                HStack {
                    leading
                    Spacer(minLength: 0)
                    trailing
                }
                content
            }
        } else {
            HStack(spacing: Theme.Spacing.l) {
                leading
                content
                Spacer(minLength: 0)
                trailing
            }
        }
    }
}
