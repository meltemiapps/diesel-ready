import SwiftUI

/// Learn tab. Phase 1 shows the header and the modules decoded from the bundled
/// JSON; the progress card and lesson navigation arrive in Phase 2.
struct LearnView: View {
    @Environment(ContentStore.self) private var content

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    LearnHeader()
                    if let error = content.loadError {
                        Callout(kind: .error, text: error)
                    } else {
                        Text("Modules")
                            .font(.sectionTitle)
                            .foregroundStyle(Theme.Palette.ink)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(content.modules) { module in
                            ModuleRow(module: module)
                        }
                    }
                }
                .padding(Theme.Spacing.l)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.Palette.background)
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

private struct LearnHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            UnofficialBadge()
            Text(AppInfo.name)
                .font(.heroTitle)
                .foregroundStyle(Theme.Palette.onHero)
                .accessibilityAddTraits(.isHeader)
            Text("Marine diesel engine care and fault-finding")
                .font(.subheadline)
                .foregroundStyle(Theme.Palette.onHeroSecondary)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous)
                .fill(Theme.Palette.navy)
        )
    }
}

struct ModuleRow: View {
    let module: Module

    var body: some View {
        HStack(spacing: Theme.Spacing.l) {
            Text("\(module.number)")
                .font(.cardTitle)
                .foregroundStyle(Theme.Palette.onHero)
                .frame(width: Theme.minTouchTarget, height: Theme.minTouchTarget)
                .background(Circle().fill(Theme.Palette.deepBlue))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(module.title)
                    .font(.cardTitle)
                    .foregroundStyle(Theme.Palette.ink)
                Text("\(module.lessons.count) lessons · \(module.estimatedMinutes) min")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Palette.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .card()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Module \(module.number), \(module.title), \(module.lessons.count) lessons, about \(module.estimatedMinutes) minutes")
    }
}

#Preview {
    LearnView()
        .environment(ContentStore())
}
