import SwiftUI

/// Fault finder tab: the STOP / DO NOT RESTART / GET ASSISTANCE cards first,
/// then symptom chips, then the chosen symptom's notices and stop cards,
/// possible causes (unranked), checks and related lessons. All wording comes
/// from `Content/faults.json` and `Content/safety.json`.
struct FaultsView: View {
    @Environment(ContentStore.self) private var content
    @Environment(AppNavigation.self) private var navigation
    @SceneStorage("faults.selectedSymptom") private var selectedID = ""
    @State private var path: [AppNavigation.LearnRoute] = []
    /// Set when a link from another tab opens a symptom, to scroll it into view.
    @State private var linkedSymptom: Symptom.ID?

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
        // A link from another tab (such as a checklist item) opens its symptom.
        .onChange(of: navigation.requestedSymptom, initial: true) { _, id in
            guard let id else { return }
            path = []
            selectedID = id
            linkedSymptom = id
            navigation.requestedSymptom = nil
        }
    }

    private func guideView(_ guide: FaultGuide) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    Text(guide.intro)
                        .foregroundStyle(Theme.Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        Text("Stop first")
                            .font(.sectionTitle)
                            .foregroundStyle(Theme.Palette.ink)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(guide.stopCards) { card in
                            StopCardView(card: card)
                        }
                    }

                    Text("What are you seeing?")
                        .font(.sectionTitle)
                        .foregroundStyle(Theme.Palette.ink)
                        .accessibilityAddTraits(.isHeader)

                    FlowLayout(spacing: Theme.Spacing.s) {
                        ForEach(guide.symptoms) { symptom in
                            SymptomChip(symptom: symptom, isSelected: symptom.id == selectedID) {
                                withAnimation(.easeInOut(duration: 0.2)) { selectedID = symptom.id }
                            }
                        }
                    }

                    if let symptom = guide.symptom(withID: selectedID) {
                        SymptomDetailView(symptom: symptom, guide: guide, library: content.library)
                            .id(symptom.id)
                    }
                }
                .padding(Theme.Spacing.l)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: linkedSymptom, initial: true) { _, id in
                guard let id else { return }
                // After the detail has been laid out.
                DispatchQueue.main.async {
                    withAnimation { proxy.scrollTo(id, anchor: .top) }
                    linkedSymptom = nil
                }
            }
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
                .foregroundStyle(isSelected ? Theme.Palette.onSelectedChip : Theme.Palette.ink)
                .padding(.horizontal, Theme.Spacing.l)
                .padding(.vertical, Theme.Spacing.xs)
                .frame(minHeight: Theme.minTouchTarget)
                .background(Capsule().fill(isSelected ? Theme.Palette.selectedChip : Theme.Palette.surface))
                .overlay(Capsule().strokeBorder(isSelected ? Color.clear : Theme.Palette.divider, lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(symptom.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "" : "Shows stop instructions, possible causes and checks")
    }
}

// MARK: - Detail

private struct SymptomDetailView: View {
    let symptom: Symptom
    let guide: FaultGuide
    let library: ContentLibrary

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text(symptom.title)
                    .font(.screenTitle)
                    .foregroundStyle(Theme.Palette.ink)
                    .accessibilityAddTraits(.isHeader)
            }

            // Safety first: the notice, then the stop cards, before any diagnosis.
            SafetyNoticeList(ids: symptom.noticeIDs, guide: library.safety)
            ForEach(symptom.cardIDs.compactMap { guide.stopCard(withID: $0) }) { card in
                StopCardView(card: card)
            }

            Text(symptom.summary)
                .foregroundStyle(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            section("Possible causes", subtitle: "Not in order of likelihood") {
                ForEach(Array(symptom.possibleCauses.enumerated()), id: \.offset) { _, cause in
                    CauseRow(cause: cause)
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

            ReminderCard(text: guide.reminder)
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

/// One possible cause. Bulleted, not numbered, because causes are not ranked.
private struct CauseRow: View {
    let cause: FaultCause

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .foregroundStyle(Theme.Palette.link)
                .accessibilityHidden(true)
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
        .accessibilityLabel("Possible cause. \(cause.title). \(cause.detail)")
    }
}

private struct CheckRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
            NumberBadge("\(number)", fill: Theme.Palette.accent, foreground: Theme.Palette.onAccent)
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

#Preview {
    FaultsView()
        .environment(ContentStore())
        .environment(AppNavigation())
}
