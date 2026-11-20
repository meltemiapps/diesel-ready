import SwiftData
import SwiftUI

/// Quiz tab: quick quiz, mock test, per-module quizzes and recent results.
struct QuizHomeView: View {
    @Environment(ContentStore.self) private var content
    @Query(sort: \QuizAttempt.finishedAt, order: .reverse) private var attempts: [QuizAttempt]

    @State private var launch: QuizLaunch?

    private var library: ContentLibrary { content.library }
    private var totalQuestions: Int { library.allQuestions.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                    if let error = content.loadError {
                        Callout(kind: .error, text: error)
                    }

                    ModeCard(
                        title: "Quick quiz",
                        detail: "\(QuizMode.quickCount) random questions from across the guide.",
                        systemImage: "bolt.fill",
                        note: availabilityNote(requested: QuizMode.quickCount),
                        isPrimary: true,
                        isEnabled: totalQuestions > 0
                    ) { launch = QuizLaunch(mode: .quick) }

                    ModeCard(
                        title: "Mock test",
                        detail: "\(QuizMode.mockCount) questions spread across every module, with results by module.",
                        systemImage: "doc.text.magnifyingglass",
                        note: availabilityNote(requested: QuizMode.mockCount),
                        isPrimary: false,
                        isEnabled: totalQuestions > 0
                    ) { launch = QuizLaunch(mode: .mock) }

                    Text("By module")
                        .font(.sectionTitle)
                        .foregroundStyle(Theme.Palette.ink)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.top, Theme.Spacing.s)

                    ForEach(library.modules) { module in
                        ModuleQuizRow(module: module) {
                            launch = QuizLaunch(mode: .module(module.id))
                        }
                    }

                    if !attempts.isEmpty {
                        Text("Recent results")
                            .font(.sectionTitle)
                            .foregroundStyle(Theme.Palette.ink)
                            .accessibilityAddTraits(.isHeader)
                            .padding(.top, Theme.Spacing.s)
                        VStack(spacing: 0) {
                            ForEach(attempts.prefix(5)) { attempt in
                                AttemptRow(attempt: attempt, title: title(for: attempt))
                                if attempt.id != attempts.prefix(5).last?.id {
                                    Divider().overlay(Theme.Palette.divider)
                                }
                            }
                        }
                        .card()
                    }
                }
                .padding(Theme.Spacing.l)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
            .background(Theme.Palette.background)
            .navigationTitle("Quiz")
            .quizCover($launch)
        }
    }

    private func availabilityNote(requested: Int) -> String? {
        guard totalQuestions < requested else { return nil }
        return totalQuestions == 0
            ? "No questions available yet."
            : "Only \(totalQuestions) questions are available so far; all of them will be used."
    }

    private func title(for attempt: QuizAttempt) -> String {
        switch attempt.mode {
        case "lesson":
            let lesson = library.allLessons.first { $0.id == attempt.scopeID }
            return lesson.map { "Lesson: \($0.title)" } ?? "Lesson quiz"
        case "module":
            let module = attempt.scopeID.flatMap(library.module(withID:))
            return module.map { "Module \($0.number) quiz" } ?? "Module quiz"
        case "quick": return "Quick quiz"
        case "mock": return "Mock test"
        case "retry": return "Retry missed"
        default: return "Quiz"
        }
    }
}

private struct ModeCard: View {
    let title: String
    let detail: String
    let systemImage: String
    let note: String?
    let isPrimary: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                Image(systemName: systemImage)
                    .foregroundStyle(Theme.Palette.link)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(title)
                        .font(.cardTitle)
                        .foregroundStyle(Theme.Palette.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(Theme.Palette.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let note {
                Callout(kind: .caution, text: note)
            }
            Group {
                if isPrimary {
                    Button("Start \(title.lowercased())", action: action).buttonStyle(.primary)
                } else {
                    Button("Start \(title.lowercased())", action: action).buttonStyle(.secondary)
                }
            }
            .disabled(!isEnabled)
        }
        .card()
    }
}

private struct ModuleQuizRow: View {
    let module: Module
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AdaptiveRow {
                NumberBadge("\(module.number)", fill: Theme.Palette.deepBlue, foreground: Theme.Palette.onHero,
                            diameter: Theme.minTouchTarget, font: .cardTitle, relativeTo: .headline)
            } content: {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(module.title)
                        .font(.cardTitle)
                        .foregroundStyle(Theme.Palette.ink)
                        .multilineTextAlignment(.leading)
                    Text(module.questions.isEmpty ? "No questions yet" : "\(module.questions.count) questions")
                        .font(.subheadline)
                        .foregroundStyle(Theme.Palette.secondaryText)
                }
            } trailing: {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.Palette.link)
            }
            .card()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(module.questions.isEmpty)
        .accessibilityLabel("Module \(module.number) quiz, \(module.title), \(module.questions.count) questions")
    }
}

private struct AttemptRow: View {
    let attempt: QuizAttempt
    let title: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundStyle(Theme.Palette.ink)
                Text(attempt.finishedAt, format: .dateTime.day().month().hour().minute())
                    .font(.footnote)
                    .foregroundStyle(Theme.Palette.secondaryText)
            }
            Spacer()
            Text("\(attempt.correctCount) / \(attempt.totalCount)")
                .font(.body.monospacedDigit().weight(.semibold))
                .foregroundStyle(Theme.Palette.ink)
        }
        .padding(.vertical, Theme.Spacing.s)
        .accessibilityElement(children: .combine)
    }
}
