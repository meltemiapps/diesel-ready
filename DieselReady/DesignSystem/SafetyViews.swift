import SwiftUI

// Views for the shared safety content in `Content/safety.json` and the Fault
// finder's stop cards. Every word they show comes from the JSON.

extension String {
    /// Content text with `**bold**` emphasis, the only markup safety notices use.
    var inlineMarkdown: AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: self, options: options)) ?? AttributedString(self)
    }

    /// The same text without markup, for VoiceOver labels.
    var plainFromMarkdown: String {
        String(inlineMarkdown.characters)
    }
}

/// A verbatim safety notice. Stop-engine conditions are red; hazard warnings
/// use the caution colours.
struct SafetyNoticeView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let notice: SafetyNotice

    private var foreground: Color { notice.level == .stop ? Theme.Palette.error : Theme.Palette.caution }
    private var background: Color { notice.level == .stop ? Theme.Palette.errorBackground : Theme.Palette.cautionBackground }
    private var symbol: String { notice.level == .stop ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill" }

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.s))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.m))
        layout {
            Image(systemName: symbol)
                .font(.title3)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(notice.title)
                    .font(.cardTitle)
                Text(notice.text.inlineMarkdown)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(foreground)
        .padding(Theme.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).fill(background)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(foreground, lineWidth: 2)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(notice.title). \(notice.text.plainFromMarkdown)")
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("safety-notice-\(notice.id)")
    }
}

/// The notices with the given ids, in order. Unknown ids are skipped; the
/// content validator reports them.
struct SafetyNoticeList: View {
    let ids: [String]
    let guide: SafetyGuide?

    var body: some View {
        ForEach(ids.compactMap { guide?.notice(withID: $0) }) { notice in
            SafetyNoticeView(notice: notice)
        }
    }
}

/// STOP / DO NOT RESTART / GET ASSISTANCE for one dangerous condition.
struct StopCardView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let card: StopCard

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Label {
                Text(card.title).font(.cardTitle)
            } icon: {
                Image(systemName: "exclamationmark.octagon.fill")
            }
            .foregroundStyle(Theme.Palette.error)
            .accessibilityAddTraits(.isHeader)

            row("STOP", card.stop)
            row("DO NOT RESTART", card.doNotRestart)
            row("GET ASSISTANCE", card.getAssistance)
        }
        .padding(Theme.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).fill(Theme.Palette.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Theme.Palette.error, lineWidth: 2)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Stop card: \(card.title). Stop: \(card.stop) Do not restart: \(card.doNotRestart) Get assistance: \(card.getAssistance)")
        .accessibilityIdentifier("stop-card-\(card.id)")
    }

    private func row(_ heading: String, _ text: String) -> some View {
        // Heading above the text at accessibility sizes, so the text keeps the full width.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: Theme.Spacing.m))
        return layout {
            Text(heading)
                .font(.caption.weight(.heavy))
                .foregroundStyle(Theme.Palette.error)
                .frame(minWidth: dynamicTypeSize.isAccessibilitySize ? nil : 112, alignment: .leading)
            Text(text)
                .font(.callout)
                .foregroundStyle(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// Who a step is for: observe, owner (handbook required) or engineer only.
struct ActionBadge: View {
    let level: ActionLevel
    let label: String

    private var colours: (foreground: Color, background: Color) {
        switch level {
        case .observe: (Theme.Palette.link, Theme.Palette.background)
        case .owner: (Theme.Palette.caution, Theme.Palette.cautionBackground)
        case .engineer: (Theme.Palette.error, Theme.Palette.errorBackground)
        }
    }

    private var symbol: String {
        switch level {
        case .observe: "eye"
        case .owner: "wrench.and.screwdriver"
        case .engineer: "person.badge.shield.checkmark"
        }
    }

    var body: some View {
        Label(label, systemImage: symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(colours.foreground)
            .padding(.horizontal, Theme.Spacing.s)
            .padding(.vertical, 3)
            // A rounded rectangle rather than a capsule, so a label that wraps at
            // accessibility text sizes keeps a tidy shape.
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(colours.background))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(colours.foreground.opacity(0.5), lineWidth: 1))
    }
}

/// "Applies to" line listing the installation types a lesson is written for.
struct ApplicabilityRow: View {
    let tags: [ApplicabilityTag]

    var body: some View {
        if !tags.isEmpty {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Applies to")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.Palette.secondaryText)
                FlowLayout(spacing: Theme.Spacing.xs) {
                    ForEach(tags) { tag in
                        Text(tag.label)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.Palette.ink)
                            .padding(.horizontal, Theme.Spacing.s)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Theme.Palette.surface))
                            .overlay(Capsule().strokeBorder(Theme.Palette.divider, lineWidth: 1))
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Applies to: " + tags.map(\.label).joined(separator: ", "))
            .accessibilityIdentifier("applies-to")
        }
    }
}
