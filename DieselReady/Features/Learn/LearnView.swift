import SwiftData
import SwiftUI

/// Learn tab: header, progress card and module list, with navigation into
/// modules and lessons.
struct LearnView: View {
    @Environment(ContentStore.self) private var content
    @Environment(AppNavigation.self) private var navigation
    @Query private var progressRecords: [LessonProgress]

    private var summary: ProgressSummary {
        ProgressSummary(library: content.library, states: progressRecords.map(LessonState.init))
    }

    var body: some View {
        @Bindable var navigation = navigation
        NavigationStack(path: $navigation.learnPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    LearnHeader()
                    if let error = content.loadError {
                        Callout(kind: .error, text: error)
                    } else {
                        ProgressCard(summary: summary)
                        Text("Modules")
                            .font(.sectionTitle)
                            .foregroundStyle(Theme.Palette.ink)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.top, Theme.Spacing.s)
                        ForEach(content.modules) { module in
                            let row = ModuleRow(module: module,
                                                completedLessons: summary.completedLessonCount(in: module))
                            NavigationLink(value: AppNavigation.LearnRoute.module(module.id)) { row }
                                .buttonStyle(.plain)
                                .accessibilityLabel(row.accessibilityText)
                        }
                    }
                }
                .padding(Theme.Spacing.l)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.Palette.background)
            .toolbar(.hidden, for: .navigationBar)
            .navigationTitle("Learn")
            .navigationDestination(for: AppNavigation.LearnRoute.self) { route in
                LearnDestination(route: route)
            }
        }
    }
}

/// Resolves a route id to its content. Shows a message if the id no longer
/// exists (for example after a content update removed a lesson).
struct LearnDestination: View {
    @Environment(ContentStore.self) private var content
    let route: AppNavigation.LearnRoute

    var body: some View {
        switch route {
        case .module(let id):
            if let module = content.library.module(withID: id) {
                ModuleDetailView(module: module)
            } else {
                missing
            }
        case .lesson(let id):
            if let module = content.library.module(containingLesson: id) {
                LessonReaderView(module: module, lessonID: id)
            } else {
                missing
            }
        }
    }

    private var missing: some View {
        ContentUnavailableView("Not found", systemImage: "questionmark.folder",
                               description: Text("This item is no longer in the guide."))
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

private struct ProgressCard: View {
    @Environment(AppNavigation.self) private var navigation
    let summary: ProgressSummary

    @State private var quizLaunch: QuizLaunch?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Your progress")
                .font(.cardTitle)
                .foregroundStyle(Theme.Palette.ink)
                .accessibilityAddTraits(.isHeader)

            VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                Text("\(summary.completedModuleCount) of \(summary.library.modules.count) modules completed")
                    .foregroundStyle(Theme.Palette.ink)
                ModuleProgressBar(fraction: summary.fractionComplete)
                Text("\(summary.completedLessonCount) of \(summary.totalLessonCount) lessons read")
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.secondaryText)
            }
            .accessibilityElement(children: .combine)

            continueButton

            Button {
                quizLaunch = QuizLaunch(mode: .quick)
            } label: {
                Label("Quick quiz", systemImage: "bolt")
            }
            .buttonStyle(.secondary)
            .disabled(summary.library.allQuestions.isEmpty)
            .accessibilityHint("\(QuizMode.quickCount) random questions")
        }
        .card()
        .quizCover($quizLaunch)
    }

    @ViewBuilder
    private var continueButton: some View {
        if let position = summary.continuePosition {
            Button {
                navigation.open(position)
            } label: {
                VStack(spacing: 2) {
                    Text(summary.hasStarted ? "Continue lesson" : "Start learning")
                    Text(position.lesson.title)
                        .font(.footnote)
                        .lineLimit(1)
                }
                .padding(.vertical, Theme.Spacing.xs)
            }
            .buttonStyle(.primary)
        } else {
            Callout(kind: .success, text: "You have read every lesson. Well done.")
        }
    }
}

/// Thin rounded progress bar in the design-system colours.
struct ModuleProgressBar: View {
    let fraction: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Palette.divider)
                Capsule()
                    .fill(Theme.Palette.success)
                    .frame(width: proxy.size.width * min(max(fraction, 0), 1))
            }
        }
        .frame(height: 8)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue(Text(fraction, format: .percent.precision(.fractionLength(0))))
    }
}

struct ModuleRow: View {
    let module: Module
    let completedLessons: Int

    private var isComplete: Bool { !module.lessons.isEmpty && completedLessons == module.lessons.count }

    var body: some View {
        HStack(spacing: Theme.Spacing.l) {
            Text("\(module.number)")
                .font(.cardTitle)
                .foregroundStyle(Theme.Palette.onHero)
                .frame(width: Theme.minTouchTarget, height: Theme.minTouchTarget)
                .background(Circle().fill(Theme.Palette.deepBlue))
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(module.title)
                    .font(.cardTitle)
                    .foregroundStyle(Theme.Palette.ink)
                    .multilineTextAlignment(.leading)
                Text("\(module.lessons.count) lessons · \(module.estimatedMinutes) min")
                    .font(.subheadline)
                    .foregroundStyle(Theme.Palette.secondaryText)
                if completedLessons > 0 && !isComplete {
                    Text("\(completedLessons) of \(module.lessons.count) read")
                        .font(.footnote)
                        .foregroundStyle(Theme.Palette.secondaryText)
                }
            }
            Spacer(minLength: 0)
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.Palette.success)
            } else {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.Palette.secondaryText)
            }
        }
        .card()
        .contentShape(Rectangle())
    }

    /// Applied by the containing link, so VoiceOver reads one button.
    var accessibilityText: String {
        var text = "Module \(module.number), \(module.title). \(module.lessons.count) lessons, about \(module.estimatedMinutes) minutes."
        if isComplete {
            text += " Completed."
        } else if completedLessons > 0 {
            text += " \(completedLessons) of \(module.lessons.count) lessons read."
        }
        return text
    }
}

#Preview {
    LearnView()
        .environment(ContentStore())
        .environment(AppNavigation())
        .modelContainer(for: ProgressSchema.models, inMemory: true)
}
