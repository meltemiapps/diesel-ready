import Foundation
import SwiftData
import Testing
@testable import DieselReady

/// Deterministic generator so shuffles are repeatable in tests.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
}

enum QuizFixtures {
    /// Builds a module whose questions are spread over two lessons, with the
    /// correct answer at varying positions.
    static func module(_ number: Int, questions count: Int) -> Module {
        let id = String(format: "m%02d", number)
        let lessons = (1...2).map { l in
            Lesson(id: "\(id)-l\(l)", title: "Lesson \(l)", estimatedMinutes: 5, intro: "", diagram: nil,
                   steps: [Step(title: nil, text: "x")], caution: nil, handsOn: false, reviewStatus: .draft)
        }
        let questions = (0..<count).map { q in
            Question(id: "\(id)-q\(q)", moduleId: id, lessonId: lessons[q % 2].id, difficulty: 1,
                     prompt: "Q\(q)", options: ["A\(q)", "B\(q)", "C\(q)", "D\(q)"],
                     correctIndex: q % 4, explanation: "E", reviewStatus: .draft)
        }
        return Module(id: id, number: number, title: id, summary: "", lessons: lessons, questions: questions)
    }

    static func library(_ counts: [Int]) -> ContentLibrary {
        ContentLibrary(schemaVersion: 1, modules: counts.enumerated().map { module($0.offset + 1, questions: $0.element) })
    }
}

@Suite("Quiz: shuffling")
struct QuizShuffleTests {
    private let question = Question(id: "q", moduleId: "m01", lessonId: "l", difficulty: 1, prompt: "P",
                                    options: ["Right", "Wrong 1", "Wrong 2", "Wrong 3"], correctIndex: 0,
                                    explanation: "E", reviewStatus: .draft)

    @Test("The correct answer is tracked after every shuffle")
    func correctAnswerTracked() {
        var rng = SeededGenerator(seed: 1)
        for _ in 0..<500 {
            let presented = PresentedQuestion.shuffled(question, using: &rng)
            #expect(presented.options[presented.correctDisplayIndex] == "Right")
            #expect(presented.isCorrect(displayIndex: presented.correctDisplayIndex))
            #expect(Set(presented.options) == Set(question.options))
            for wrong in presented.options.indices where wrong != presented.correctDisplayIndex {
                #expect(!presented.isCorrect(displayIndex: wrong))
            }
        }
    }

    @Test("Tapped positions map back to the original option", arguments: [[0, 1, 2, 3], [3, 2, 1, 0], [2, 0, 3, 1]])
    func mapsBack(order: [Int]) {
        let presented = PresentedQuestion(question: question, order: order)
        for display in 0..<4 {
            #expect(presented.options[display] == question.options[presented.originalIndex(forDisplayIndex: display)])
        }
        #expect(presented.correctDisplayIndex == order.firstIndex(of: 0))
    }

    @Test("The correct answer lands in every position roughly equally")
    func positionsAreUniform() {
        var rng = SeededGenerator(seed: 42)
        var counts = [0, 0, 0, 0]
        let trials = 4000
        for _ in 0..<trials {
            counts[PresentedQuestion.shuffled(question, using: &rng).correctDisplayIndex] += 1
        }
        for count in counts {
            #expect((800...1200).contains(count), "position counts \(counts)")
        }
    }

    @Test("Options are shuffled every time a question is shown, including on retry")
    @MainActor
    func sessionReshufflesEachShow() {
        let library = QuizFixtures.library([2])
        let selection = QuizSelection(questions: library.allQuestions, requestedCount: nil)
        var shownIDs: [String] = []
        var rng = SeededGenerator(seed: 99)
        let shuffler: QuizSession.Shuffler = { q in
            shownIDs.append(q.id)
            return PresentedQuestion.shuffled(q, using: &rng)
        }

        let first = QuizSession(mode: .module("m01"), selection: selection, shuffler: shuffler)
        let firstOrder = first.current?.order
        first.choose(displayIndex: 0)
        first.advance()
        #expect(shownIDs == ["m01-q0", "m01-q1"])

        // Retrying shows the same question again with a fresh shuffle.
        var retryOrders: Set<[Int]> = []
        for _ in 0..<20 {
            let retry = QuizSession(mode: .retry(["m01-q0"]),
                                    selection: QuizSelection(questions: [library.allQuestions[0]], requestedCount: nil),
                                    shuffler: shuffler)
            if let order = retry.current?.order { retryOrders.insert(order) }
        }
        #expect(shownIDs.count == 22)
        #expect(retryOrders.count > 1, "retries should not reuse one fixed order")
        #expect(firstOrder != nil)
    }
}

@Suite("Quiz: question selection")
struct QuizSelectionTests {

    @Test("Quick quiz takes 10 unique questions when enough exist")
    func quickFull() {
        var rng = SeededGenerator(seed: 7)
        let selection = QuestionSelector.select(.quick, from: QuizFixtures.library([20, 20]), using: &rng)
        #expect(selection.questions.count == 10)
        #expect(Set(selection.questions.map(\.id)).count == 10)
        #expect(!selection.isShort)
        #expect(selection.shortfallMessage == nil)
    }

    @Test("Quick quiz uses all questions, without repeats, when fewer than 10 exist")
    func quickShort() {
        var rng = SeededGenerator(seed: 7)
        let selection = QuestionSelector.select(.quick, from: QuizFixtures.library([6]), using: &rng)
        #expect(selection.questions.count == 6)
        #expect(Set(selection.questions.map(\.id)).count == 6)
        #expect(selection.isShort)
        #expect(selection.shortfallMessage?.contains("Only 6 questions") == true)
    }

    @Test("Mock test with only 17 questions uses all 17 once and says so")
    func mockShortLikeModuleOne() {
        var rng = SeededGenerator(seed: 3)
        let selection = QuestionSelector.select(.mock, from: QuizFixtures.library([17]), using: &rng)
        #expect(selection.questions.count == 17)
        #expect(Set(selection.questions.map(\.id)).count == 17)
        #expect(selection.shortfallMessage == "Only 17 questions are available so far, so this quiz uses all of them instead of 30.")
    }

    @Test("Mock test spreads 30 questions evenly across modules")
    func mockSpread() {
        var rng = SeededGenerator(seed: 9)
        let selection = QuestionSelector.select(.mock, from: QuizFixtures.library([20, 20, 20]), using: &rng)
        #expect(selection.questions.count == 30)
        #expect(Set(selection.questions.map(\.id)).count == 30)
        let perModule = Dictionary(grouping: selection.questions, by: \.moduleId).mapValues(\.count)
        #expect(perModule == ["m01": 10, "m02": 10, "m03": 10])
    }

    @Test("Mock test takes all of a small module and fills from the others")
    func mockUneven() {
        var rng = SeededGenerator(seed: 11)
        let selection = QuestionSelector.select(.mock, from: QuizFixtures.library([3, 40, 40]), using: &rng)
        let perModule = Dictionary(grouping: selection.questions, by: \.moduleId).mapValues(\.count)
        #expect(selection.questions.count == 30)
        #expect(Set(selection.questions.map(\.id)).count == 30)
        #expect(perModule["m01"] == 3)
        #expect(abs((perModule["m02"] ?? 0) - (perModule["m03"] ?? 0)) <= 1)
    }

    @Test("Lesson and module quizzes use exactly their own questions")
    func scopedModes() {
        var rng = SeededGenerator(seed: 5)
        let library = QuizFixtures.library([8, 6])
        let lesson = QuestionSelector.select(.lesson("m01-l1"), from: library, using: &rng)
        #expect(Set(lesson.questions.map(\.id)) == Set(library.allQuestions.filter { $0.lessonId == "m01-l1" }.map(\.id)))
        #expect(lesson.questions.count == 4)
        #expect(lesson.shortfallMessage == nil)

        let module = QuestionSelector.select(.module("m02"), from: library, using: &rng)
        #expect(Set(module.questions.map(\.id)) == Set(library.modules[1].questions.map(\.id)))
    }

    @Test("Retry uses only the missed questions and ignores unknown ids")
    func retry() {
        var rng = SeededGenerator(seed: 5)
        let selection = QuestionSelector.select(.retry(["m01-q2", "m01-q5", "gone"]), from: QuizFixtures.library([8]), using: &rng)
        #expect(Set(selection.questions.map(\.id)) == ["m01-q2", "m01-q5"])
    }

    @Test("No questions at all gives an empty, explained selection")
    func empty() {
        var rng = SeededGenerator(seed: 5)
        let selection = QuestionSelector.select(.mock, from: QuizFixtures.library([0]), using: &rng)
        #expect(selection.questions.isEmpty)
        #expect(selection.shortfallMessage == "There are no questions available for this quiz yet.")
    }

    @Test("Bundled content: mock test uses every available question once")
    func bundledMock() throws {
        let library = try ContentLoader.bundled(.main).load()
        let selection = QuestionSelector.select(.mock, from: library)
        #expect(selection.questions.count == min(library.allQuestions.count, 30))
        #expect(Set(selection.questions.map(\.id)).count == selection.questions.count)
    }
}

@Suite("Quiz: scoring and session")
@MainActor
struct QuizScoringTests {

    private func answer(_ q: Question, correct: Bool) -> AnsweredQuestion {
        AnsweredQuestion(question: q, chosenIndex: correct ? q.correctIndex : (q.correctIndex + 1) % 4)
    }

    @Test("Score, percentage, missed list and module breakdown")
    func scoring() {
        let library = QuizFixtures.library([3, 2])
        let qs = library.allQuestions // m01-q0..2, m02-q0..1
        let result = QuizResult(mode: .mock, answers: [
            answer(qs[0], correct: true), answer(qs[1], correct: false), answer(qs[2], correct: true),
            answer(qs[3], correct: false), answer(qs[4], correct: false),
        ])
        #expect(result.correctCount == 2)
        #expect(result.totalCount == 5)
        #expect(result.percentage == 40)
        #expect(result.missedQuestionIDs == ["m01-q1", "m02-q0", "m02-q1"])
        #expect(result.moduleScores(moduleOrder: ["m01", "m02"]) == [
            .init(moduleID: "m01", correct: 2, total: 3),
            .init(moduleID: "m02", correct: 0, total: 2),
        ])
    }

    @Test("Percentage rounds to the nearest whole number and handles zero questions")
    func percentage() {
        let qs = QuizFixtures.library([3]).allQuestions
        let twoOfThree = QuizResult(mode: .quick, answers: [
            answer(qs[0], correct: true), answer(qs[1], correct: true), answer(qs[2], correct: false),
        ])
        #expect(twoOfThree.percentage == 67)
        #expect(QuizResult(mode: .quick, answers: []).percentage == 0)
    }

    @Test("Session records the original option even though the display order is shuffled")
    func sessionScoresShuffledAnswers() {
        let library = QuizFixtures.library([2])
        let selection = QuizSelection(questions: library.allQuestions, requestedCount: nil)
        // Reverse the options so display positions never match the JSON order.
        let session = QuizSession(mode: .module("m01"), selection: selection) {
            PresentedQuestion(question: $0, order: [3, 2, 1, 0])
        }

        // Question 0: correctIndex 0 is shown at display 3. Tap it.
        #expect(session.current?.correctDisplayIndex == 3)
        session.choose(displayIndex: 3)
        session.choose(displayIndex: 0) // ignored: already answered
        #expect(session.answers.last?.chosenIndex == 0)
        #expect(session.answers.last?.isCorrect == true)
        session.advance()

        // Question 1: correctIndex 1 is shown at display 2. Tap display 0 (original 3): wrong.
        #expect(session.current?.correctDisplayIndex == 2)
        session.choose(displayIndex: 0)
        #expect(session.answers.last?.chosenIndex == 3)
        #expect(session.isLastQuestion)
        session.advance()

        #expect(session.isFinished)
        #expect(session.result.correctCount == 1)
        #expect(session.result.missedQuestionIDs == ["m01-q1"])
    }

    @Test("Cannot advance without answering")
    func mustAnswer() {
        let selection = QuizSelection(questions: QuizFixtures.library([2]).allQuestions, requestedCount: nil)
        let session = QuizSession(mode: .quick, selection: selection)
        session.advance()
        #expect(session.index == 0)
        #expect(!session.isFinished)
    }

    @Test("Finished quizzes are saved to SwiftData")
    func recordsAttempt() throws {
        let container = try ModelContainer(for: Schema(ProgressSchema.models),
                                           configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let qs = QuizFixtures.library([2]).allQuestions
        let result = QuizResult(mode: .lesson("m01-l1"), answers: [answer(qs[0], correct: true), answer(qs[1], correct: false)])

        try QuizRecorder.record(result, in: context, now: Date(timeIntervalSince1970: 100))

        let saved = try context.fetch(FetchDescriptor<QuizAttempt>())
        #expect(saved.count == 1)
        #expect(saved.first?.mode == "lesson")
        #expect(saved.first?.scopeID == "m01-l1")
        #expect(saved.first?.correctCount == 1)
        #expect(saved.first?.totalCount == 2)
        #expect(saved.first?.missedQuestionIDs == ["m01-q1"])
    }
}
