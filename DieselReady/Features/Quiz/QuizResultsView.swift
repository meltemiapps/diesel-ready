import SwiftUI

/// Score summary, optional results by module, and the missed questions with
/// explanations.
struct QuizResultsView: View {
    let result: QuizResult
    let library: ContentLibrary
    let saveError: String?
    let onRetryMissed: () -> Void
    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                scoreCard

                if let saveError {
                    Callout(kind: .error, text: saveError)
                }

                if result.mode.showsModuleBreakdown {
                    moduleBreakdown
                }

                if result.missed.isEmpty {
                    Callout(kind: .success, text: "You answered every question correctly.")
                } else {
                    Text("Questions to review")
                        .font(.sectionTitle)
                        .foregroundStyle(Theme.Palette.ink)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(result.missed) { answer in
                        MissedQuestionCard(answer: answer)
                    }
                }

                VStack(spacing: Theme.Spacing.m) {
                    if !result.missed.isEmpty {
                        Button {
                            onRetryMissed()
                        } label: {
                            Label("Retry missed (\(result.missed.count))", systemImage: "arrow.counterclockwise")
                        }
                        .buttonStyle(.primary)
                    }
                    Button("Done", action: onDone)
                        .buttonStyle(.secondary)
                }
                .padding(.top, Theme.Spacing.s)
            }
            .padding(Theme.Spacing.l)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
    }

    private var scoreCard: some View {
        VStack(spacing: Theme.Spacing.s) {
            Text("Your score")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.Palette.onHeroSecondary)
            Text("\(result.correctCount) / \(result.totalCount)")
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.Palette.onHero)
            Text("\(result.percentage)%")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.Palette.accent)
            Text(message)
                .font(.callout)
                .foregroundStyle(Theme.Palette.onHeroSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Theme.Radius.hero, style: .continuous)
                .fill(Theme.Palette.navy)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Your score: \(result.correctCount) out of \(result.totalCount), \(result.percentage) percent. \(message)")
    }

    private var message: String {
        switch result.percentage {
        case 90...: "Excellent work."
        case 70..<90: "Good. Review the questions you missed."
        case 50..<70: "Getting there. Re-read the lessons behind the missed questions."
        default: "Worth another look at the lessons before you try again."
        }
    }

    private var moduleBreakdown: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Text("Results by module")
                .font(.cardTitle)
                .foregroundStyle(Theme.Palette.ink)
                .accessibilityAddTraits(.isHeader)
            ForEach(result.moduleScores(moduleOrder: library.modules.map(\.id))) { score in
                let module = library.module(withID: score.moduleID)
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(module.map { "\($0.number). \($0.title)" } ?? score.moduleID)
                            .foregroundStyle(Theme.Palette.ink)
                        Spacer()
                        Text("\(score.correct) / \(score.total)")
                            .font(.body.monospacedDigit().weight(.semibold))
                            .foregroundStyle(Theme.Palette.ink)
                    }
                    ModuleProgressBar(fraction: score.total == 0 ? 0 : Double(score.correct) / Double(score.total))
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(module?.title ?? score.moduleID): \(score.correct) out of \(score.total)")
            }
        }
        .card()
    }
}

private struct MissedQuestionCard: View {
    let answer: AnsweredQuestion

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            Text(answer.question.prompt)
                .font(.headline)
                .foregroundStyle(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Label {
                Text("Your answer: \(answer.chosenAnswer)")
            } icon: {
                Image(systemName: "xmark.circle.fill").accessibilityHidden(true)
            }
            .foregroundStyle(Theme.Palette.error)
            Label {
                Text("Correct answer: \(answer.question.correctAnswer)")
            } icon: {
                Image(systemName: "checkmark.circle.fill").accessibilityHidden(true)
            }
            .foregroundStyle(Theme.Palette.success)
            Text(answer.question.explanation)
                .font(.callout)
                .foregroundStyle(Theme.Palette.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.subheadline)
        .card()
        .accessibilityElement(children: .combine)
    }
}
