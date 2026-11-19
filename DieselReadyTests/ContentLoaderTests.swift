import Foundation
import Testing
@testable import DieselReady

@Suite("Content loading")
struct ContentLoaderTests {
    // Unit tests run inside the host app, so Bundle.main holds the bundled content.

    @Test("Bundled content decodes and passes validation")
    func bundledContentLoads() throws {
        let library = try ContentLoader.bundled(.main).load()
        #expect(!library.modules.isEmpty)
        #expect(library.modules.first?.id == "m01")
        #expect(library.allQuestions.allSatisfy { $0.reviewStatus == .draft })
        #expect(library.allLessons.allSatisfy { $0.reviewStatus == .draft })
    }

    @Test("Every bundled lesson has at least 3 questions and every module 3 to 6 lessons")
    func lessonQuestionCounts() throws {
        let library = try ContentLoader.bundled(.main).load()
        for module in library.modules {
            #expect((3...6).contains(module.lessons.count), "\(module.id) has \(module.lessons.count) lessons")
            for lesson in module.lessons {
                let count = module.questions(forLesson: lesson.id).count
                #expect(count >= 3, "\(lesson.id) has \(count) questions")
            }
        }
    }

    @Test("Bundled course meets the release volume rules")
    func bundledVolume() throws {
        let library = try ContentLoader.bundled(.main).load()
        #expect(library.modules.count == 8)
        #expect(library.allQuestions.count >= 150)
        #expect(ContentLoader.validate(library, rules: .release).isEmpty)
        for module in library.modules {
            #expect(Set(module.questions.map(\.difficulty)) == [1, 2, 3], "\(module.id) difficulty spread")
        }
        // Review notes, where present, are real sentences.
        let notes = library.allLessons.compactMap(\.reviewNote) + library.allQuestions.compactMap(\.reviewNote)
        #expect(!notes.isEmpty)
        #expect(notes.allSatisfy { $0.count > 10 })
    }

    // MARK: Volume rules

    private static func lesson(_ id: String) -> Lesson {
        Lesson(id: id, title: "L", estimatedMinutes: 5, intro: "", diagram: nil,
               steps: [Step(title: nil, text: "x")], caution: nil, handsOn: false, reviewStatus: .draft)
    }

    private static func question(_ id: String, lesson: String, difficulty: Int = 1, prompt: String? = nil) -> Question {
        Question(id: id, moduleId: "m01", lessonId: lesson, difficulty: difficulty, prompt: prompt ?? "Prompt \(id)?",
                 options: ["a", "b", "c", "d"], correctIndex: 0, explanation: "E", reviewStatus: .draft)
    }

    @Test("Release rules flag too few lessons, too few questions per lesson and missing difficulties")
    func volumeRules() {
        let lessons = [Self.lesson("m01-l01"), Self.lesson("m01-l02")]
        let questions = [Self.question("m01-q1", lesson: "m01-l01"), Self.question("m01-q2", lesson: "m01-l01", difficulty: 3)]
        let library = ContentLibrary(schemaVersion: 1, modules: [
            Module(id: "m01", number: 1, title: "T", summary: "", lessons: lessons, questions: questions),
        ])
        var rules = ContentRules.release
        rules.minTotalQuestions = 150
        let problems = ContentLoader.validate(library, rules: rules)
        #expect(problems.contains("m01: has 2 lessons, expected 3 to 6"))
        #expect(problems.contains("m01-l01: has 2 questions, needs at least 3"))
        #expect(problems.contains("m01-l02: has 0 questions, needs at least 3"))
        #expect(problems.contains("m01: has no difficulty 2 questions"))
        #expect(!problems.contains("m01: has no difficulty 3 questions"))
        #expect(problems.contains("Only 2 questions in total, needs at least 150"))

        #expect(ContentLoader.validate(library, rules: .structural).isEmpty)
    }

    @Test("Seven lessons in a module is too many")
    func tooManyLessons() {
        let lessons = (1...7).map { Self.lesson("m01-l0\($0)") }
        let library = ContentLibrary(schemaVersion: 1, modules: [
            Module(id: "m01", number: 1, title: "T", summary: "", lessons: lessons, questions: []),
        ])
        #expect(ContentLoader.validate(library).contains("m01: has 7 lessons, expected 3 to 6"))
    }

    @Test("Duplicate question text is flagged, ignoring case, spacing and punctuation")
    func duplicatePrompts() {
        let questions = [
            Self.question("m01-q1", lesson: "m01-l01", prompt: "What does the impeller do?"),
            Self.question("m01-q2", lesson: "m01-l01", prompt: "  what does the IMPELLER do "),
            Self.question("m01-q3", lesson: "m01-l01", prompt: "What does the thermostat do?"),
        ]
        let library = ContentLibrary(schemaVersion: 1, modules: [
            Module(id: "m01", number: 1, title: "T", summary: "", lessons: [Self.lesson("m01-l01")], questions: questions),
        ])
        let problems = ContentLoader.validate(library, rules: .structural)
        #expect(problems == ["m01-q2: same question text as m01-q1"])
    }

    @Test("Flow diagrams accept 2 to 7 stages")
    func flowDiagramLabels() {
        func problems(labels count: Int) -> [String] {
            let diagram = Diagram(kind: "flow", caption: nil,
                                  labels: (0..<count).map { DiagramLabel(title: "S\($0)", detail: nil) }, description: "d")
            let lesson = Lesson(id: "m01-l01", title: "L", estimatedMinutes: 5, intro: "", diagram: diagram,
                                steps: [Step(title: nil, text: "x")], caution: nil, handsOn: false, reviewStatus: .draft)
            let library = ContentLibrary(schemaVersion: 1, modules: [
                Module(id: "m01", number: 1, title: "T", summary: "", lessons: [lesson], questions: []),
            ])
            return ContentLoader.validate(library, rules: .structural)
        }
        #expect(problems(labels: 1).contains("m01-l01: diagram flow has 1 labels, expected 2 to 7"))
        #expect(problems(labels: 4).isEmpty)
        #expect(problems(labels: 8).contains { $0.contains("expected 2 to 7") })
    }

    @Test("reviewNote is optional and decodes when present")
    func reviewNoteDecodes() throws {
        let json = #"{"id":"q","moduleId":"m01","lessonId":"l","difficulty":1,"prompt":"P","options":["a","b","c","d"],"correctIndex":0,"explanation":"E","reviewStatus":"draft","reviewNote":"Check this"}"#
        let question = try JSONDecoder().decode(Question.self, from: Data(json.utf8))
        #expect(question.reviewNote == "Check this")
        let without = json.replacingOccurrences(of: #","reviewNote":"Check this""#, with: "")
        #expect(try JSONDecoder().decode(Question.self, from: Data(without.utf8)).reviewNote == nil)
    }

    @Test("Validation reports structural problems")
    func validationCatchesErrors() throws {
        let loader = ContentLoader.inMemory([
            "manifest.json": #"{"schemaVersion":1,"modules":["a.json"]}"#,
            "modules/a.json": Self.moduleJSON(correctIndex: 7, lessonID: "nope", options: 3),
        ])
        #expect {
            try loader.load()
        } throws: { error in
            guard case ContentLoader.LoadError.invalid(let problems) = error else { return false }
            return problems.contains { $0.contains("correctIndex") }
                && problems.contains { $0.contains("unknown lessonId") }
                && problems.contains { $0.contains("expected 4") }
        }
    }

    @Test("A diagram with the wrong number of labels is reported")
    func diagramLabelCount() {
        let diagram = Diagram(kind: "four-stroke-cycle", caption: nil,
                              labels: [DiagramLabel(title: "Only one", detail: nil)], description: "d")
        let lesson = Lesson(id: "m01-l01", title: "L", estimatedMinutes: 5, intro: "", diagram: diagram,
                            steps: [Step(title: nil, text: "x")], caution: nil, handsOn: false, reviewStatus: .draft)
        let library = ContentLibrary(schemaVersion: 1, modules: [
            Module(id: "m01", number: 1, title: "T", summary: "", lessons: [lesson], questions: []),
        ])
        #expect(ContentLoader.validate(library).contains { $0.contains("expected 4") })
    }

    @Test("A newer schema version is rejected")
    func rejectsNewerSchema() {
        let loader = ContentLoader.inMemory([
            "manifest.json": #"{"schemaVersion":99,"modules":[]}"#,
        ])
        #expect(throws: ContentLoader.LoadError.unsupportedSchema(99)) { try loader.load() }
    }

    @Test("A missing module file is reported by name")
    func missingFile() {
        let loader = ContentLoader.inMemory([
            "manifest.json": #"{"schemaVersion":1,"modules":["gone.json"]}"#,
        ])
        #expect(throws: ContentLoader.LoadError.missingFile("modules/gone.json")) { try loader.load() }
    }

    @Test("Disclaimer reappears when its version is bumped")
    func disclaimerVersioning() {
        #expect(!Disclaimer.isAccepted(storedVersion: 0))
        #expect(!Disclaimer.isAccepted(storedVersion: Disclaimer.currentVersion - 1))
        #expect(Disclaimer.isAccepted(storedVersion: Disclaimer.currentVersion))
    }

    // MARK: Helpers

    private static func moduleJSON(correctIndex: Int, lessonID: String, options: Int) -> String {
        let opts = (1...options).map { "\"Option \($0)\"" }.joined(separator: ",")
        return """
        {"id":"m01","number":1,"title":"T","summary":"S",
         "lessons":[{"id":"m01-l01","title":"L","estimatedMinutes":5,"intro":"I","diagram":null,
           "steps":[{"title":null,"text":"Step"}],"caution":null,"handsOn":false,"reviewStatus":"draft"}],
         "questions":[{"id":"m01-q001","moduleId":"m01","lessonId":"\(lessonID)","difficulty":1,
           "prompt":"P","options":[\(opts)],"correctIndex":\(correctIndex),"explanation":"E","reviewStatus":"draft"}]}
        """
    }
}

extension ContentLoader {
    static func inMemory(_ files: [String: String]) -> ContentLoader {
        ContentLoader(rules: .structural) { path in
            guard let text = files[path] else { throw LoadError.missingFile(path) }
            return Data(text.utf8)
        }
    }
}
