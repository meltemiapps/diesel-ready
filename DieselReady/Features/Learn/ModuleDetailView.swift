import SwiftData
import SwiftUI

/// A module's summary and its lesson list.
struct ModuleDetailView: View {
    @Environment(ContentStore.self) private var content
    @Query private var progressRecords: [LessonProgress]

    let module: Module

    private var summary: ProgressSummary {
        ProgressSummary(library: content.library, states: progressRecords.map(LessonState.init))
    }

    var body: some View {
        let summary = summary
        let completed = summary.completedLessonCount(in: module)

        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text("Module \(module.number)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Palette.onHeroSecondary)
                    Text(module.title)
                        .font(.screenTitle)
                        .foregroundStyle(Theme.Palette.onHero)
                        .accessibilityAddTraits(.isHeader)
                    Text(module.summary)
                        .foregroundStyle(Theme.Palette.onHeroSecondary)
                }
                .padding(Theme.Spacing.xl)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous)
                        .fill(Theme.Palette.navy)
                )

                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    Text("\(completed) of \(module.lessons.count) lessons read · about \(module.estimatedMinutes) min")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Palette.secondaryText)
                    ModuleProgressBar(fraction: module.lessons.isEmpty ? 0 : Double(completed) / Double(module.lessons.count))
                }
                .accessibilityElement(children: .combine)

                Text("Lessons")
                    .font(.sectionTitle)
                    .foregroundStyle(Theme.Palette.ink)
                    .accessibilityAddTraits(.isHeader)

                ForEach(Array(module.lessons.enumerated()), id: \.element.id) { index, lesson in
                    NavigationLink(value: AppNavigation.LearnRoute.lesson(lesson.id)) {
                        LessonRow(
                            number: index + 1,
                            lesson: lesson,
                            isCompleted: summary.isCompleted(lesson: lesson.id),
                            isStarted: summary.isStarted(lesson: lesson.id)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(Theme.Spacing.l)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(Theme.Palette.background)
        .navigationTitle("Module \(module.number)")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LessonRow: View {
    let number: Int
    let lesson: Lesson
    let isCompleted: Bool
    let isStarted: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.l) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Theme.Palette.successBackground : Theme.Palette.background)
                Circle()
                    .strokeBorder(isCompleted ? Theme.Palette.success : Theme.Palette.divider, lineWidth: 1.5)
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.headline)
                        .foregroundStyle(Theme.Palette.success)
                } else {
                    Text("\(number)")
                        .font(.cardTitle)
                        .foregroundStyle(Theme.Palette.ink)
                }
            }
            .frame(width: Theme.minTouchTarget, height: Theme.minTouchTarget)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(lesson.title)
                    .font(.cardTitle)
                    .foregroundStyle(Theme.Palette.ink)
                    .multilineTextAlignment(.leading)
                HStack(spacing: Theme.Spacing.s) {
                    Text("\(lesson.estimatedMinutes) min")
                    if lesson.handsOn {
                        Label("Hands-on", systemImage: "hand.raised")
                    }
                    if isStarted && !isCompleted {
                        Text("In progress")
                    }
                }
                .font(.footnote)
                .foregroundStyle(Theme.Palette.secondaryText)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .foregroundStyle(Theme.Palette.secondaryText)
        }
        .card()
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityAddTraits(.isButton)
    }

    private var accessibilityText: String {
        var text = "Lesson \(number), \(lesson.title), \(lesson.estimatedMinutes) minutes."
        if lesson.handsOn { text += " Hands-on." }
        if isCompleted {
            text += " Completed."
        } else if isStarted {
            text += " In progress."
        }
        return text
    }
}
