import Foundation
import Observation

/// View model for one run through a quiz: one question at a time, instant
/// feedback, then a result.
@MainActor
@Observable
final class QuizSession {
    typealias Shuffler = (Question) -> PresentedQuestion

    let mode: QuizMode
    let selection: QuizSelection

    private(set) var index = 0
    /// The current question with freshly shuffled options.
    private(set) var current: PresentedQuestion?
    /// Shuffled position the learner tapped for the current question, if any.
    private(set) var selectedDisplayIndex: Int?
    private(set) var answers: [AnsweredQuestion] = []
    private(set) var isFinished = false

    private let shuffler: Shuffler

    init(mode: QuizMode, selection: QuizSelection, shuffler: @escaping Shuffler = QuizSession.randomShuffle) {
        self.mode = mode
        self.selection = selection
        self.shuffler = shuffler
        showCurrent()
    }

    nonisolated static func randomShuffle(_ question: Question) -> PresentedQuestion {
        var rng = SystemRandomNumberGenerator()
        return PresentedQuestion.shuffled(question, using: &rng)
    }

    // MARK: State

    var questionCount: Int { selection.questions.count }
    var isEmpty: Bool { selection.questions.isEmpty }
    var hasAnswered: Bool { selectedDisplayIndex != nil }
    var isLastQuestion: Bool { index + 1 >= questionCount }
    /// "Question 3 of 10"
    var positionText: String { "Question \(min(index + 1, questionCount)) of \(questionCount)" }

    var result: QuizResult { QuizResult(mode: mode, answers: answers) }

    // MARK: Actions

    /// Records the learner's choice. Further taps on the same question are ignored.
    func choose(displayIndex: Int) {
        guard let current, selectedDisplayIndex == nil,
              current.order.indices.contains(displayIndex) else { return }
        selectedDisplayIndex = displayIndex
        answers.append(AnsweredQuestion(
            question: current.question,
            chosenIndex: current.originalIndex(forDisplayIndex: displayIndex)
        ))
    }

    /// Moves to the next question, or finishes after the last one.
    func advance() {
        guard hasAnswered else { return }
        if isLastQuestion {
            isFinished = true
        } else {
            index += 1
            showCurrent()
        }
    }

    /// Shuffles the options each time a question is shown.
    private func showCurrent() {
        selectedDisplayIndex = nil
        current = selection.questions.indices.contains(index) ? shuffler(selection.questions[index]) : nil
    }
}
