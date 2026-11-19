import Foundation

// Pure quiz logic: which questions a quiz uses, how options are shuffled and
// how answers are scored. No UI or storage, so it is fully unit-testable.

// MARK: - Modes

enum QuizMode: Hashable, Sendable {
    /// All questions for one lesson ("Check your knowledge").
    case lesson(Lesson.ID)
    /// All questions for one module.
    case module(Module.ID)
    /// Ten random questions from the whole guide.
    case quick
    /// Thirty questions spread across all modules, with results by module.
    case mock
    /// The questions missed in a previous quiz.
    case retry([Question.ID])

    static let quickCount = 10
    static let mockCount = 30

    /// Stable string stored with each attempt.
    var kind: String {
        switch self {
        case .lesson: "lesson"
        case .module: "module"
        case .quick: "quick"
        case .mock: "mock"
        case .retry: "retry"
        }
    }

    /// Lesson or module id for scoped quizzes.
    var scopeID: String? {
        switch self {
        case .lesson(let id), .module(let id): id
        case .quick, .mock, .retry: nil
        }
    }

    /// How many questions the mode asks for, or nil when it simply uses all
    /// questions in its scope.
    var requestedCount: Int? {
        switch self {
        case .quick: Self.quickCount
        case .mock: Self.mockCount
        case .lesson, .module, .retry: nil
        }
    }

    /// Whether results are broken down by module.
    var showsModuleBreakdown: Bool {
        if case .mock = self { return true }
        return false
    }

    func title(in library: ContentLibrary) -> String {
        switch self {
        case .lesson(let id):
            let lesson = library.allLessons.first { $0.id == id }
            return lesson.map { "Quiz: \($0.title)" } ?? "Lesson quiz"
        case .module(let id):
            let module = library.module(withID: id)
            return module.map { "Module \($0.number) quiz" } ?? "Module quiz"
        case .quick: return "Quick quiz"
        case .mock: return "Mock test"
        case .retry: return "Retry missed"
        }
    }
}

// MARK: - Selection

struct QuizSelection: Sendable, Equatable {
    let questions: [Question]
    /// What the mode asked for, when it asks for a fixed number.
    let requestedCount: Int?

    var isShort: Bool {
        guard let requestedCount else { return false }
        return questions.count < requestedCount
    }

    /// Explains a shortfall on screen, e.g. a 30-question mock test when only
    /// 17 questions exist yet.
    var shortfallMessage: String? {
        guard isShort, let requestedCount else { return nil }
        if questions.isEmpty { return "There are no questions available for this quiz yet." }
        return "Only \(questions.count) questions are available so far, so this quiz uses all of them instead of \(requestedCount)."
    }
}

enum QuestionSelector {

    /// Picks the questions for a mode. Never repeats a question; if the mode
    /// asks for more than exist, it returns every available question.
    static func select<R: RandomNumberGenerator>(
        _ mode: QuizMode, from library: ContentLibrary, using rng: inout R
    ) -> QuizSelection {
        let questions: [Question]
        switch mode {
        case .lesson(let id):
            questions = library.allQuestions.filter { $0.lessonId == id }.shuffled(using: &rng)
        case .module(let id):
            questions = (library.module(withID: id)?.questions ?? []).shuffled(using: &rng)
        case .quick:
            questions = Array(library.allQuestions.shuffled(using: &rng).prefix(QuizMode.quickCount))
        case .mock:
            questions = spread(library.modules.map(\.questions), count: QuizMode.mockCount, using: &rng)
        case .retry(let ids):
            let wanted = Set(ids)
            questions = library.allQuestions.filter { wanted.contains($0.id) }.shuffled(using: &rng)
        }
        return QuizSelection(questions: questions, requestedCount: mode.requestedCount)
    }

    static func select(_ mode: QuizMode, from library: ContentLibrary) -> QuizSelection {
        var rng = SystemRandomNumberGenerator()
        return select(mode, from: library, using: &rng)
    }

    /// Takes up to `count` questions spread as evenly as possible across the
    /// groups (modules): one from each group in turn, skipping groups that run
    /// out. The final order is shuffled so modules are mixed.
    static func spread<R: RandomNumberGenerator>(
        _ groups: [[Question]], count: Int, using rng: inout R
    ) -> [Question] {
        let pools = groups.map { $0.shuffled(using: &rng) }
        var picked: [Question] = []
        var round = 0
        while picked.count < count {
            var tookAny = false
            for index in pools.indices where round < pools[index].count {
                picked.append(pools[index][round])
                tookAny = true
                if picked.count == count { break }
            }
            if !tookAny { break }
            round += 1
        }
        return picked.shuffled(using: &rng)
    }
}

// MARK: - Shuffled presentation

/// A question as shown on screen, with its options in a shuffled order.
struct PresentedQuestion: Sendable, Equatable {
    let question: Question
    /// `order[displayIndex]` is the index of that option in `question.options`.
    let order: [Int]

    init(question: Question, order: [Int]) {
        precondition(order.sorted() == Array(question.options.indices), "order must be a permutation")
        self.question = question
        self.order = order
    }

    /// Shuffles the options. Call each time the question is shown.
    static func shuffled<R: RandomNumberGenerator>(_ question: Question, using rng: inout R) -> PresentedQuestion {
        PresentedQuestion(question: question, order: Array(question.options.indices).shuffled(using: &rng))
    }

    var options: [String] { order.map { question.options[$0] } }

    /// Where the correct answer sits after shuffling.
    var correctDisplayIndex: Int {
        // Safe: order is a permutation of the option indices, so correctIndex is in it.
        order.firstIndex(of: question.correctIndex)!
    }

    /// Converts a tapped position back to the option's index in the JSON.
    func originalIndex(forDisplayIndex displayIndex: Int) -> Int {
        order[displayIndex]
    }

    func isCorrect(displayIndex: Int) -> Bool {
        originalIndex(forDisplayIndex: displayIndex) == question.correctIndex
    }
}

// MARK: - Scoring

struct AnsweredQuestion: Sendable, Equatable, Identifiable {
    let question: Question
    /// Index into `question.options` (not the shuffled position).
    let chosenIndex: Int

    var id: Question.ID { question.id }
    var isCorrect: Bool { chosenIndex == question.correctIndex }
    var chosenAnswer: String { question.options[chosenIndex] }
}

struct QuizResult: Sendable, Equatable {
    struct ModuleScore: Sendable, Equatable, Identifiable {
        let moduleID: Module.ID
        let correct: Int
        let total: Int
        var id: Module.ID { moduleID }
    }

    let mode: QuizMode
    let answers: [AnsweredQuestion]

    var totalCount: Int { answers.count }
    var correctCount: Int { answers.filter(\.isCorrect).count }
    var missed: [AnsweredQuestion] { answers.filter { !$0.isCorrect } }
    var missedQuestionIDs: [Question.ID] { missed.map(\.question.id) }

    /// Whole-number percentage, rounded to nearest.
    var percentage: Int {
        totalCount == 0 ? 0 : Int((Double(correctCount) / Double(totalCount) * 100).rounded())
    }

    /// Scores per module, in the order modules first appear in `moduleOrder`.
    func moduleScores(moduleOrder: [Module.ID]) -> [ModuleScore] {
        let grouped = Dictionary(grouping: answers, by: \.question.moduleId)
        return moduleOrder.compactMap { id in
            guard let answers = grouped[id] else { return nil }
            return ModuleScore(moduleID: id, correct: answers.filter(\.isCorrect).count, total: answers.count)
        }
    }
}
