import SwiftUI

/// One question: prompt, four shuffled options, instant feedback and the explanation.
struct QuizQuestionView: View {
    let session: QuizSession

    var body: some View {
        if let current = session.current {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.l) {
                        Color.clear.frame(height: 0).id(Anchor.top)
                        if session.index == 0, let message = session.selection.shortfallMessage {
                            Callout(kind: .caution, text: message)
                        }

                        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                            Text(session.positionText)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Theme.Palette.secondaryText)
                            ModuleProgressBar(fraction: Double(session.index + 1) / Double(max(session.questionCount, 1)))
                                .accessibilityLabel("Quiz progress")
                                .accessibilityValue(session.positionText)
                        }

                        Text(current.question.prompt)
                            .font(.sectionTitle)
                            .foregroundStyle(Theme.Palette.ink)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)

                        VStack(spacing: Theme.Spacing.m) {
                            ForEach(Array(current.options.enumerated()), id: \.offset) { displayIndex, option in
                                OptionButton(
                                    letter: Self.letters[displayIndex],
                                    text: option,
                                    state: state(for: displayIndex, in: current)
                                ) {
                                    // Not .disabled(): that would fade the green/red feedback.
                                    guard !session.hasAnswered else { return }
                                    session.choose(displayIndex: displayIndex)
                                    announce(current: current, chosen: displayIndex)
                                    withAnimation { proxy.scrollTo(Anchor.feedback, anchor: .bottom) }
                                }
                            }
                        }

                        if let chosen = session.selectedDisplayIndex {
                            feedback(current: current, chosen: chosen)
                                .id(Anchor.feedback)
                        }
                    }
                    .padding(Theme.Spacing.l)
                    .frame(maxWidth: 700)
                    .frame(maxWidth: .infinity)
                    // New identity per question so focus resets.
                    .id(current.question.id)
                }
                // Each new question starts at the top. Without this, at large text
                // sizes the next question opened where the last one was scrolled to,
                // below its own options.
                .onChange(of: session.index) {
                    proxy.scrollTo(Anchor.top, anchor: .top)
                }
            }
        }
    }

    private enum Anchor: Hashable { case top, feedback }
    private static let letters = ["A", "B", "C", "D"]

    private func state(for displayIndex: Int, in current: PresentedQuestion) -> OptionButton.State {
        guard let chosen = session.selectedDisplayIndex else { return .idle }
        if displayIndex == current.correctDisplayIndex { return .correct }
        if displayIndex == chosen { return .wrong }
        return .dimmed
    }

    private func feedback(current: PresentedQuestion, chosen: Int) -> some View {
        let correct = current.isCorrect(displayIndex: chosen)
        return VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            Callout(
                kind: correct ? .success : .error,
                text: (correct ? "Correct. " : "Not quite. The answer is \u{201C}\(current.question.correctAnswer)\u{201D}. ")
                    + current.question.explanation
            )
            Button(session.isLastQuestion ? "See results" : "Next question") {
                withAnimation { session.advance() }
            }
            .buttonStyle(.primary)
        }
    }

    private func announce(current: PresentedQuestion, chosen: Int) {
        let text = current.isCorrect(displayIndex: chosen) ? "Correct" : "Incorrect"
        AccessibilityNotification.Announcement(text).post()
    }
}

/// An answer option that turns green when correct and red when wrongly picked.
private struct OptionButton: View {
    enum State { case idle, correct, wrong, dimmed }

    let letter: String
    let text: String
    let state: State
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
                NumberBadge(letter, stroke: foreground, foreground: foreground)
                Text(text)
                    .foregroundStyle(state == .dimmed ? Theme.Palette.secondaryText : Theme.Palette.ink)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let symbol {
                    Image(systemName: symbol)
                        .foregroundStyle(foreground)
                }
            }
            .padding(Theme.Spacing.l)
            .frame(minHeight: Theme.minTouchTarget)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                    .fill(background)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous)
                    .strokeBorder(border, lineWidth: state == .idle || state == .dimmed ? 1 : 2)
            )
            .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
        }
        .buttonStyle(.plain)
        // Label on the Button itself so VoiceOver keeps the button trait.
        .accessibilityLabel("\(letter). \(text)")
        .accessibilityValue(accessibilityState)
    }

    private var foreground: Color {
        switch state {
        case .idle: Theme.Palette.link
        case .correct: Theme.Palette.success
        case .wrong: Theme.Palette.error
        case .dimmed: Theme.Palette.secondaryText
        }
    }

    private var background: Color {
        switch state {
        case .idle, .dimmed: Theme.Palette.surface
        case .correct: Theme.Palette.successBackground
        case .wrong: Theme.Palette.errorBackground
        }
    }

    private var border: Color {
        switch state {
        case .idle, .dimmed: Theme.Palette.divider
        case .correct: Theme.Palette.success
        case .wrong: Theme.Palette.error
        }
    }

    private var symbol: String? {
        switch state {
        case .correct: "checkmark.circle.fill"
        case .wrong: "xmark.circle.fill"
        case .idle, .dimmed: nil
        }
    }

    private var accessibilityState: String {
        switch state {
        case .idle: ""
        case .correct: "Correct answer"
        case .wrong: "Your answer, incorrect"
        case .dimmed: ""
        }
    }
}
