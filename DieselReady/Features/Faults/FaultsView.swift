import SwiftUI

/// Fault finder tab: symptom chips, then the chosen symptom's causes, checks
/// and related lessons. All wording comes from `Content/faults.json`.
struct FaultsView: View {
    @Environment(ContentStore.self) private var content
    @SceneStorage("faults.selectedSymptom") private var selectedID = ""
    @State private var path: [AppNavigation.LearnRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let error = content.loadError {
                    ScrollView { Callout(kind: .error, text: error).padding(Theme.Spacing.l) }
                } else if let guide = content.library.faults {
                    guideView(guide)
                } else {
                    ContentUnavailableView("No fault finder content", systemImage: "wrench.and.screwdriver")
                }
            }
            .background(Theme.Palette.background)
            .navigationTitle("Fault finder")
            .navigationDestination(for: AppNavigation.LearnRoute.self) { route in
                LearnDestination(route: route)
            }
        }
    }

    private func guideView(_ guide: FaultGuide) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                Text(guide.intro)
                    .foregroundStyle(Theme.Palette.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                FlowLayout(spacing: Theme.Spacing.s) {
                    ForEach(guide.symptoms) { symptom in
                        SymptomChip(symptom: symptom, isSelected: symptom.id == selectedID) {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedID = symptom.id }
                        }
                    }
                }

                if let symptom = guide.symptom(withID: selectedID) {
                    SymptomDetailView(symptom: symptom, reminder: guide.reminder, library: content.library)
                        .id(symptom.id)
                }
            }
            .padding(Theme.Spacing.l)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
    }
}

/// SF Symbol for each symptom. Icons are not content, so they live here
/// rather than in the shared JSON.
enum SymptomIcon {
    static func name(for id: Symptom.ID) -> String {
        switch id {
        case "exhaust-smoke": "smoke.fill"
        case "wont-start": "key.fill"
        case "overheating": "thermometer.high"
        case "stops-suddenly": "stop.circle.fill"
        case "low-oil-pressure": "drop.fill"
        case "not-charging": "minus.plus.batteryblock.fill"
        default: "wrench.and.screwdriver.fill"
        }
    }
}

private struct SymptomChip: View {
    let symptom: Symptom
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(symptom.title, systemImage: SymptomIcon.name(for: symptom.id))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSelected ? Theme.Palette.onHero : Theme.Palette.ink)
                .padding(.horizontal, Theme.Spacing.l)
                .frame(minHeight: Theme.minTouchTarget)
                .background(Capsule().fill(isSelected ? Theme.Palette.navy : Theme.Palette.surface))
                .overlay(Capsule().strokeBorder(isSelected ? Color.clear : Theme.Palette.divider, lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symptom.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "" : "Shows likely causes and checks")
    }
}

// MARK: - Detail

private struct SymptomDetailView: View {
    let symptom: Symptom
    let reminder: String
    let library: ContentLibrary

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(symptom.title)
                    .font(.screenTitle)
                    .foregroundStyle(Theme.Palette.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(symptom.summary)
                    .foregroundStyle(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let stop = symptom.stopFirst {
                StopFirstCallout(instruction: stop)
            }

            section("Likely causes", subtitle: "Most likely first") {
                ForEach(Array(symptom.causes.enumerated()), id: \.offset) { index, cause in
                    CauseRow(rank: index + 1, cause: cause)
                }
            }

            section("What to check first", subtitle: nil) {
                VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                    ForEach(Array(symptom.checkFirst.enumerated()), id: \.offset) { index, check in
                        CheckRow(number: index + 1, text: check)
                    }
                }
                .card()
            }

            let lessons = symptom.lessonIds.compactMap { id in
                library.module(containingLesson: id).flatMap { module in
                    module.lessons.firstIndex { $0.id == id }.map { (module, module.lessons[$0], $0 + 1) }
                }
            }
            if !lessons.isEmpty {
                section("Related lessons", subtitle: nil) {
                    ForEach(lessons, id: \.1.id) { module, lesson, number in
                        let text = "Module \(module.number), lesson \(number): \(lesson.title)"
                        NavigationLink(value: AppNavigation.LearnRoute.lesson(lesson.id)) {
                            LessonLinkRow(moduleNumber: module.number, lessonNumber: number, title: lesson.title)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(text)
                    }
                }
            }

            ReminderCard(text: reminder)
        }
    }

    private func section<Content: View>(_ title: String, subtitle: String?,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.sectionTitle)
                    .foregroundStyle(Theme.Palette.ink)
                    .accessibilityAddTraits(.isHeader)
                if let subtitle {
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.secondaryText)
                }
            }
            content()
        }
    }
}

/// Prominent instruction shown before any diagnosis.
private struct StopFirstCallout: View {
    let instruction: StopInstruction

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
            Image(systemName: "exclamationmark.octagon.fill")
                .font(.title2)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(instruction.title)
                    .font(.cardTitle)
                Text(instruction.text)
                    .font(.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Theme.Palette.error)
        .padding(Theme.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .fill(Theme.Palette.errorBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Theme.Palette.error, lineWidth: 2)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(instruction.title). \(instruction.text)")
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("stop-first")
    }
}

private struct CauseRow: View {
    let rank: Int
    let cause: FaultCause

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
            Text("\(rank)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.Palette.onHero)
                .frame(minWidth: 28, minHeight: 28)
                .background(Circle().fill(Theme.Palette.deepBlue))
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(cause.title)
                    .font(.headline)
                    .foregroundStyle(Theme.Palette.ink)
                Text(cause.detail)
                    .foregroundStyle(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .card()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Cause \(rank). \(cause.title). \(cause.detail)")
    }
}

private struct CheckRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
            Text("\(number)")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.Palette.onAccent)
                .frame(minWidth: 28, minHeight: 28)
                .background(Circle().fill(Theme.Palette.accent))
            Text(text)
                .foregroundStyle(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Check \(number). \(text)")
    }
}

private struct LessonLinkRow: View {
    let moduleNumber: Int
    let lessonNumber: Int
    let title: String

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: "book.fill")
                .foregroundStyle(Theme.Palette.link)
            VStack(alignment: .leading, spacing: 2) {
                Text("Module \(moduleNumber) · Lesson \(lessonNumber)")
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.secondaryText)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Theme.Palette.ink)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.Palette.secondaryText)
        }
        .frame(minHeight: Theme.minTouchTarget)
        .card()
        .contentShape(Rectangle())
    }
}

private struct ReminderCard: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
            Image(systemName: "book.closed.fill")
                .foregroundStyle(Theme.Palette.link)
                .accessibilityHidden(true)
            Text(text)
                .font(.callout)
                .foregroundStyle(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .card()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("fault-reminder")
    }
}

// MARK: - Layout

/// Lays out children left to right, wrapping onto new lines as needed, so
/// the chips stay readable at large Dynamic Type sizes.
struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(ProposedViewSize(width: width, height: nil))
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

#Preview {
    FaultsView()
        .environment(ContentStore())
        .environment(AppNavigation())
}
