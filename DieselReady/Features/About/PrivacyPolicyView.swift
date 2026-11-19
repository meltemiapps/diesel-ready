import SwiftUI

/// Full privacy policy, readable offline.
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                Text("Last updated \(PrivacyPolicy.lastUpdated)")
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.secondaryText)
                ForEach(PrivacyPolicy.sections) { section in
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text(section.heading)
                            .font(.sectionTitle)
                            .foregroundStyle(Theme.Palette.ink)
                            .accessibilityAddTraits(.isHeader)
                        Text(section.body)
                            .foregroundStyle(Theme.Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Link("View this policy online", destination: AppInfo.privacyURL)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.Palette.link)
                    .frame(minHeight: Theme.minTouchTarget)
            }
            .padding(Theme.Spacing.l)
            .frame(maxWidth: 700, alignment: .leading)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.Palette.background)
        .navigationTitle("Privacy policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { PrivacyPolicyView() }
}
