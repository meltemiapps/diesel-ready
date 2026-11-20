import SwiftUI

/// Ticks on the Checks tab. Held in memory for this session only: nothing is
/// saved to the device or sent anywhere, so every launch starts unticked.
struct ChecklistTicks: Equatable, Sendable {
    private(set) var ticked: Set<ChecklistItem.ID> = []

    func isTicked(_ id: ChecklistItem.ID) -> Bool { ticked.contains(id) }

    mutating func toggle(_ id: ChecklistItem.ID) {
        if ticked.remove(id) == nil { ticked.insert(id) }
    }

    /// Clears every tick in every checklist.
    mutating func reset() { ticked.removeAll() }

    /// How many of the checklist's items are ticked.
    func count(in checklist: Checklist) -> Int {
        checklist.items.filter { ticked.contains($0.id) }.count
    }

    var isEmpty: Bool { ticked.isEmpty }
}

/// Checks tab: the pre-start (engine off) and post-start (engine running)
/// checklists, with items to tick, each linked to its lesson. All wording
/// comes from `Content/checklists.json` and `Content/safety.json`.
struct ChecksView: View {
    @Environment(ContentStore.self) private var content
    @Environment(AppNavigation.self) private var navigation
    @State private var ticks = ChecklistTicks()
    @State private var path: [AppNavigation.LearnRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let error = content.loadError {
                    ScrollView { Callout(kind: .error, text: error).padding(Theme.Spacing.l) }
                } else if let guide = content.library.checks {
                    guideView(guide)
                } else {
                    ContentUnavailableView("No checklists", systemImage: "checklist")
                }
            }
            .background(Theme.Palette.background)
            .navigationTitle("Engine checks")
            .navigationDestination(for: AppNavigation.LearnRoute.self) { route in
                LearnDestination(route: route)
            }
        }
        // A link from a lesson shows its checklist from the top of the stack.
        .onChange(of: navigation.checklistRequests) { path = [] }
    }

    private func guideView(_ guide: ChecklistGuide) -> some View {
        @Bindable var navigation = navigation
        let selected = guide.checklist(withID: navigation.selectedChecklist) ?? guide.checklists.first
        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    Picker("Checklist", selection: $navigation.selectedChecklist) {
                        ForEach(guide.checklists) { list in
                            Text(list.title).tag(list.id)
                        }
                    }
                    .pickerStyle(.segmented)
                    .id(ScrollAnchor.top)

                    if let selected {
                        ChecklistView(checklist: selected, guide: guide, library: content.library,
                                      ticks: $ticks, onReset: { withAnimation { ticks.reset() } },
                                      openSymptom: { navigation.showSymptom($0) })
                            .id(selected.id)
                    }
                }
                .padding(Theme.Spacing.l)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .onChange(of: navigation.selectedChecklist) {
                proxy.scrollTo(ScrollAnchor.top, anchor: .top)
            }
        }
    }

    private enum ScrollAnchor: Hashable { case top }
}

// MARK: - One checklist

private struct ChecklistView: View {
    let checklist: Checklist
    let guide: ChecklistGuide
    let library: ContentLibrary
    @Binding var ticks: ChecklistTicks
    let onReset: () -> Void
    let openSymptom: (Symptom.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            // Running engine: the observe-only banner comes before anything else.
            if checklist.engineRunning, let banner = checklist.banner {
                RunningBanner(text: banner)
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("\(checklist.title): \(checklist.subtitle.lowercased())")
                    .font(.screenTitle)
                    .foregroundStyle(Theme.Palette.ink)
                    .accessibilityAddTraits(.isHeader)
                Text(checklist.intro)
                    .foregroundStyle(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            MnemonicCard(aid: guide.mnemonic, checklist: checklist)

            HStack(alignment: .center, spacing: Theme.Spacing.l) {
                ProgressRow(done: ticks.count(in: checklist), total: checklist.items.count)
                Button("Reset", action: onReset)
                    .font(.headline)
                    .foregroundStyle(ticks.isEmpty ? Theme.Palette.secondaryText : Theme.Palette.link)
                    .frame(minWidth: Theme.minTouchTarget, minHeight: Theme.minTouchTarget)
                    .contentShape(Rectangle())
                    .disabled(ticks.isEmpty)
                    .accessibilityHint("Clears every tick in both checklists")
                    .accessibilityIdentifier("checks-reset")
            }

            ForEach(checklist.sections) { section in
                SectionView(section: section, library: library, ticks: $ticks, openSymptom: openSymptom)
            }

            if let module = library.module(containingLesson: checklist.lessonId),
               let index = module.lessons.firstIndex(where: { $0.id == checklist.lessonId }) {
                let lesson = module.lessons[index]
                NavigationLink(value: AppNavigation.LearnRoute.lesson(lesson.id)) {
                    LinkRow(symbol: "book.fill", caption: "Read the lesson · Module \(module.number) · Lesson \(index + 1)",
                            title: lesson.title)
                        .card()
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Read the lesson. Module \(module.number), lesson \(index + 1): \(lesson.title)")
                .accessibilityIdentifier("checks-lesson-link")
            }

            ReminderRow(text: guide.reminder)

            Button("Reset all ticks", action: onReset)
                .buttonStyle(.secondary)
                .disabled(ticks.isEmpty)
                .accessibilityHint("Clears every tick in both checklists")
                .accessibilityIdentifier("checks-reset-bottom")
        }
    }
}

private struct RunningBanner: View {
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
            Image(systemName: "eye.trianglebadge.exclamationmark.fill")
                .font(.title3)
                .accessibilityHidden(true)
            Text(text)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .foregroundStyle(Theme.Palette.caution)
        .padding(Theme.Spacing.l)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous).fill(Theme.Palette.cautionBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(Theme.Palette.caution, lineWidth: 2)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("checks-running-banner")
    }
}

/// The memory aid's letters, with the ones this checklist covers highlighted.
private struct MnemonicCard: View {
    let aid: Mnemonic
    let checklist: Checklist

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            lettersText
                .fixedSize(horizontal: false, vertical: true)
            Text(aid.summary)
                .font(.callout)
                .foregroundStyle(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .card()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(aid.name). \(aid.summary) This checklist covers \(coveredWords).")
        .accessibilityIdentifier("checks-mnemonic")
    }

    /// One wrapping line of text, so it scales with Dynamic Type like any other:
    /// each letter large, then its word; the letters this checklist covers in
    /// the link colour, the others in secondary text.
    private var lettersText: Text {
        lettersInList.enumerated().reduce(Text("")) { text, element in
            let (index, entry) = element
            let colour = entry.covered ? Theme.Palette.link : Theme.Palette.secondaryText
            let letter = Text(entry.letter.letter)
                .font(.system(.title2, design: .rounded).weight(.heavy))
                .foregroundStyle(colour)
            let word = Text("\u{00A0}\(entry.letter.word)")
                .font(.subheadline.weight(entry.covered ? .bold : .regular))
                .foregroundStyle(colour)
            let gap = Text(index == 0 ? "" : "   ")
            return text + gap + letter + word
        }
    }

    /// Each letter of the aid, marked when this checklist has its section.
    /// Letters can repeat (two Bs), so words are matched rather than letters.
    private var lettersInList: [(letter: MnemonicLetter, covered: Bool)] {
        let sectionWords = checklist.sections.filter { $0.letter != nil }.map(\.title)
        return aid.letters.map { ($0, sectionWords.contains($0.word)) }
    }

    private var coveredWords: String {
        lettersInList.filter(\.covered).map(\.letter.word).joined(separator: ", ")
    }
}

private struct ProgressRow: View {
    let done: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("\(done) of \(total) checked")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(done == total ? Theme.Palette.success : Theme.Palette.secondaryText)
            ModuleProgressBar(fraction: total == 0 ? 0 : Double(done) / Double(total))
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(done) of \(total) checked")
        .accessibilityIdentifier("checks-progress")
    }
}

// MARK: - Sections and items

private struct SectionView: View {
    let section: ChecklistSection
    let library: ContentLibrary
    @Binding var ticks: ChecklistTicks
    let openSymptom: (Symptom.ID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(spacing: Theme.Spacing.m) {
                if let letter = section.letter {
                    NumberBadge(letter, fill: Theme.Palette.accent, foreground: Theme.Palette.onAccent,
                                diameter: 32, font: .headline.weight(.heavy), relativeTo: .headline)
                        .accessibilityHidden(true)
                }
                Text(section.title)
                    .font(.sectionTitle)
                    .foregroundStyle(Theme.Palette.ink)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(section.letter.map { "\($0): \(section.title)" } ?? section.title)
            .accessibilityAddTraits(.isHeader)

            ForEach(section.items) { item in
                ItemView(item: item, library: library, isTicked: ticks.isTicked(item.id),
                         toggle: { ticks.toggle(item.id) }, openSymptom: openSymptom)
            }
        }
    }
}

private struct ItemView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let item: ChecklistItem
    let library: ContentLibrary
    let isTicked: Bool
    let toggle: () -> Void
    let openSymptom: (Symptom.ID) -> Void

    private var actionLabel: String? { library.safety?.info(for: item.action)?.label }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Button(action: toggle) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                    Image(systemName: isTicked ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundStyle(isTicked ? Theme.Palette.success : Theme.Palette.secondaryText)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(item.title)
                            .font(.headline)
                            .foregroundStyle(Theme.Palette.ink)
                        if let actionLabel {
                            ActionBadge(level: item.action, label: actionLabel)
                        }
                        Text(item.detail)
                            .foregroundStyle(Theme.Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: Theme.minTouchTarget)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityText)
            .accessibilityValue(isTicked ? "Ticked" : "Not ticked")
            .accessibilityAddTraits(isTicked ? .isSelected : [])
            .accessibilityHint(isTicked ? "Double-tap to untick" : "Double-tap to tick")
            .accessibilityIdentifier("check-\(item.id)")

            // Shared wording, referenced by id rather than copied into the checklist.
            SafetyNoticeList(ids: item.noticeIDs, guide: library.safety)

            let links = lessonLink
            if links != nil || item.symptomId != nil {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    if let link = links {
                        let number = "\(link.module.number).\(link.number)"
                        NavigationLink(value: AppNavigation.LearnRoute.lesson(link.lesson.id)) {
                            LinkRow(symbol: "book.fill", caption: "Lesson \(number)", title: link.lesson.title)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Lesson \(number): \(link.lesson.title)")
                        .accessibilityIdentifier("check-lesson-\(item.id)")
                    }
                    if let symptomID = item.symptomId, let symptom = library.faults?.symptom(withID: symptomID) {
                        Button { openSymptom(symptomID) } label: {
                            LinkRow(symbol: "wrench.and.screwdriver.fill", caption: "Fault finder", title: symptom.title)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Fault finder: \(symptom.title)")
                        .accessibilityIdentifier("check-fault-\(item.id)")
                    }
                }
                .padding(.leading, dynamicTypeSize.isAccessibilitySize ? 0 : 36)
            }
        }
        .card()
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .strokeBorder(isTicked ? Theme.Palette.success : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.15), value: isTicked)
    }

    private var lessonLink: (module: Module, number: Int, lesson: Lesson)? {
        guard let module = library.module(containingLesson: item.lessonId),
              let index = module.lessons.firstIndex(where: { $0.id == item.lessonId }) else { return nil }
        return (module, index + 1, module.lessons[index])
    }

    private var accessibilityText: String {
        let action = actionLabel.map { " \($0)." } ?? ""
        return "\(item.title).\(action) \(item.detail)"
    }
}

/// A compact link with an icon, a caption and a title, at least 44pt high.
private struct LinkRow: View {
    let symbol: String
    let caption: String
    let title: String

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: symbol)
                .foregroundStyle(Theme.Palette.link)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(Theme.Palette.secondaryText)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Palette.link)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote)
                .foregroundStyle(Theme.Palette.secondaryText)
                .accessibilityHidden(true)
        }
        .frame(minHeight: Theme.minTouchTarget)
        .contentShape(Rectangle())
    }
}

private struct ReminderRow: View {
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
        .accessibilityIdentifier("checks-reminder")
    }
}

#Preview {
    ChecksView()
        .environment(ContentStore())
        .environment(AppNavigation())
}
