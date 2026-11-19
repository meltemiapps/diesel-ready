import SwiftUI

/// First-launch disclaimer. Shown before anything else until accepted.
struct DisclaimerView: View {
    let onAccept: () -> Void

    @State private var understood = false
    @State private var showingPrivacy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                header
                statementCard
                checkbox
                Button("Agree and continue", action: onAccept)
                    .buttonStyle(.primary)
                    .disabled(!understood)
                    .accessibilityHint(understood ? "" : "Tick the checkbox above first")
                Button("Read the privacy policy") { showingPrivacy = true }
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.Palette.onHero)
                    .underline()
                    .frame(maxWidth: .infinity, minHeight: Theme.minTouchTarget)
            }
            .padding(Theme.Spacing.xl)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.Palette.navy.ignoresSafeArea())
        .sheet(isPresented: $showingPrivacy) {
            NavigationStack {
                PrivacyPolicyView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showingPrivacy = false }
                        }
                    }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.Palette.accent)
                .accessibilityHidden(true)
            Text(AppInfo.name)
                .font(.heroTitle)
                .foregroundStyle(Theme.Palette.onHero)
                .accessibilityAddTraits(.isHeader)
            Text(Disclaimer.subtitle)
                .font(.title3)
                .foregroundStyle(Theme.Palette.onHeroSecondary)
        }
        .padding(.top, Theme.Spacing.xl)
    }

    private var statementCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Before you start")
                .font(.cardTitle)
                .foregroundStyle(Theme.Palette.ink)
                .accessibilityAddTraits(.isHeader)
            ForEach(Disclaimer.points, id: \.self) { point in
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(Theme.Palette.secondaryText)
                        .accessibilityHidden(true)
                    Text(point)
                        .foregroundStyle(Theme.Palette.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .card()
    }

    private var checkbox: some View {
        Button {
            understood.toggle()
        } label: {
            HStack(alignment: .top, spacing: Theme.Spacing.m) {
                Image(systemName: understood ? "checkmark.square.fill" : "square")
                    .font(.title2)
                    .foregroundStyle(understood ? Theme.Palette.accent : Theme.Palette.onHero)
                Text(Disclaimer.checkboxLabel)
                    .foregroundStyle(Theme.Palette.onHero)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: Theme.minTouchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Disclaimer.checkboxLabel)
        .accessibilityValue(understood ? "Ticked" : "Not ticked")
        .accessibilityAddTraits(understood ? [.isButton, .isSelected] : .isButton)
    }
}

#Preview {
    DisclaimerView {}
}
