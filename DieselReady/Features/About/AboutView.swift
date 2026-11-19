import SwiftData
import SwiftUI

struct AboutView: View {
    @Environment(\.modelContext) private var modelContext

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
                    Text("Unofficial study guide")
                }

                Section("Privacy") {
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

                Section("Safety and trademarks") {
                    Text(AppInfo.safetyNotice)
                        .foregroundStyle(Theme.Palette.ink)
                    Text(AppInfo.trademarkNotice)
                        .foregroundStyle(Theme.Palette.secondaryText)
                }

                Section("Your progress") {
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

                Section("Support and source") {
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
                    Text("Licences")
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

#Preview {
    AboutView()
        .modelContainer(for: ProgressSchema.models, inMemory: true)
}
