import SwiftData
import SwiftUI

struct AboutView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ContentStore.self) private var content

    @State private var confirmingReset = false
    @State private var resetMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        UnofficialBadge()
                        Text(AppInfo.unofficialStatement)
                            .foregroundStyle(Theme.Palette.ink)
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                } header: {
                    AboutHeader("Unofficial study guide")
                }

                Section(header: AboutHeader("Privacy")) {
                    ForEach(AppInfo.privacySummary, id: \.self) { line in
                        Label {
                            Text(line).foregroundStyle(Theme.Palette.ink)
                        } icon: {
                            Image(systemName: "checkmark.shield")
                                .foregroundStyle(Theme.Palette.success)
                                .accessibilityHidden(true)
                        }
                    }
                    NavigationLink("Privacy policy") {
                        PrivacyPolicyView()
                    }
                }

                if let info = content.library.info {
                    ContentInfoSection(info: info)
                }

                Section(header: AboutHeader("Safety and trademarks")) {
                    Text(AppInfo.safetyNotice)
                        .foregroundStyle(Theme.Palette.ink)
                    Text(AppInfo.trademarkNotice)
                        .foregroundStyle(Theme.Palette.secondaryText)
                }

                Section(header: AboutHeader("Your progress")) {
                    Button("Reset progress", role: .destructive) {
                        confirmingReset = true
                    }
                    .frame(minHeight: Theme.minTouchTarget)
                    if let resetMessage {
                        Text(resetMessage)
                            .font(.footnote)
                            .foregroundStyle(Theme.Palette.secondaryText)
                    }
                }

                Section(header: AboutHeader("Support and source")) {
                    LinkRow(title: "Email support", detail: AppInfo.supportEmail,
                            systemImage: "envelope", url: AppInfo.supportEmailURL)
                    LinkRow(title: "Website", detail: "meltemiapps.co.uk/diesel-ready",
                            systemImage: "safari", url: AppInfo.websiteURL)
                    LinkRow(title: "Source code on GitHub", detail: "meltemiapps/diesel-ready",
                            systemImage: "chevron.left.forwardslash.chevron.right", url: AppInfo.repositoryURL)
                }

                Section {
                    LinkRow(title: "Code licence", detail: "MIT",
                            systemImage: "doc.text", url: AppInfo.codeLicenceURL)
                    LinkRow(title: "Content licence", detail: "CC BY-NC-SA 4.0",
                            systemImage: "doc.richtext", url: AppInfo.contentLicenceURL)
                } header: {
                    AboutHeader("Licences")
                } footer: {
                    Text("\(AppInfo.name) \(AppInfo.version) · © 2026 \(AppInfo.studio)")
                        .frame(maxWidth: .infinity)
                        .padding(.top, Theme.Spacing.l)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Palette.background)
            .navigationTitle("About")
            .confirmationDialog(
                "Reset all progress?",
                isPresented: $confirmingReset,
                titleVisibility: .visible
            ) {
                Button("Reset progress", role: .destructive, action: resetProgress)
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This removes completed lessons, quiz results and bookmarks from this device. It cannot be undone.")
            }
        }
    }

    private func resetProgress() {
        do {
            try ProgressSchema.resetAll(in: modelContext)
            resetMessage = "Progress has been reset."
        } catch {
            resetMessage = "Progress could not be reset. Please try again."
        }
    }
}

/// A row that opens an external link (website, email, licence).
private struct LinkRow: View {
    let title: String
    let detail: String
    let systemImage: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            HStack(spacing: Theme.Spacing.m) {
                Image(systemName: systemImage)
                    .frame(width: 24)
                    .foregroundStyle(Theme.Palette.link)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).foregroundStyle(Theme.Palette.ink)
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.secondaryText)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right")
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.secondaryText)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: Theme.minTouchTarget)
        }
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens outside the app")
    }
}

/// A section header in the theme's secondary text colour, which meets WCAG AA
/// (the system default grey only just misses it on the app background).
private struct AboutHeader: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title).foregroundStyle(Theme.Palette.secondaryText)
    }
}

/// Content version, review date, engineer approval and the latest change.
private struct ContentInfoSection: View {
    let info: ContentInfo

    private func row(_ label: String, _ value: String) -> some View {
        LabeledContent {
            Text(value).foregroundStyle(Theme.Palette.secondaryText)
        } label: {
            Text(label).foregroundStyle(Theme.Palette.ink)
        }
    }

    var body: some View {
        Section {
            row("Content version", info.isApproved ? info.version : "\(info.version) (\(info.status))")
            row("Content reviewed", ContentInfoFormat.date(info.reviewDate))
            if info.isApproved {
                Label {
                    Text("Technical review: approved by a qualified marine engineer")
                        .foregroundStyle(Theme.Palette.ink)
                } icon: {
                    Image(systemName: "checkmark.seal")
                        .foregroundStyle(Theme.Palette.success)
                        .accessibilityHidden(true)
                }
                .accessibilityIdentifier("engineer-approval")
            } else {
                Label {
                    Text("Engineer approval: \(info.engineerApproval)")
                        .foregroundStyle(Theme.Palette.ink)
                } icon: {
                    Image(systemName: "hourglass")
                        .foregroundStyle(Theme.Palette.link)
                        .accessibilityHidden(true)
                }
                .accessibilityIdentifier("engineer-approval")
            }
            if let latest = info.changeLog.first {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("What changed in \(latest.version)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Palette.ink)
                    Text(latest.summary)
                        .font(.callout)
                        .foregroundStyle(Theme.Palette.ink)
                }
                .padding(.vertical, Theme.Spacing.xs)
                .accessibilityElement(children: .combine)
            }
            NavigationLink("Change log") {
                ChangeLogView(entries: info.changeLog)
            }
        } header: {
            AboutHeader("Content")
        } footer: {
            Text(info.isApproved
                 ? LocalizedStringKey("A qualified marine engineer has reviewed this version of the content. It is still general guidance: always follow your engine handbook.")
                 : "The content is a draft until a qualified marine engineer has approved it.")
                .foregroundStyle(Theme.Palette.secondaryText)
        }
    }
}

private struct ChangeLogView: View {
    let entries: [ChangeLogEntry]

    var body: some View {
        List(entries, id: \.self) { entry in
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Version \(entry.version) · \(ContentInfoFormat.date(entry.date))")
                    .font(.headline)
                    .foregroundStyle(Theme.Palette.ink)
                Text(entry.summary)
                    .foregroundStyle(Theme.Palette.ink)
            }
            .padding(.vertical, Theme.Spacing.xs)
            .accessibilityElement(children: .combine)
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Palette.background)
        .navigationTitle("Change log")
    }
}

enum ContentInfoFormat {
    /// "2026-11-20" as "20 November 2026"; the raw text if it is not a date.
    static func date(_ text: String) -> String {
        guard let date = ContentInfo.date(from: text) else { return text }
        var style = Date.FormatStyle(date: .long, time: .omitted)
        style.locale = Locale(identifier: "en_GB")
        style.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return date.formatted(style)
    }
}

#Preview {
    AboutView()
        .modelContainer(for: ProgressSchema.models, inMemory: true)
        .environment(ContentStore())
}
