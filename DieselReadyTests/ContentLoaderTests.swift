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

    @Test("Every lesson in the sample module has 3 to 5 questions")
    func lessonQuestionCounts() throws {
        let library = try ContentLoader.bundled(.main).load()
        for module in library.modules {
            for lesson in module.lessons {
                let count = module.questions(forLesson: lesson.id).count
                #expect((3...5).contains(count), "\(lesson.id) has \(count) questions")
            }
        }
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

private extension ContentLoader {
    static func inMemory(_ files: [String: String]) -> ContentLoader {
        ContentLoader { path in
            guard let text = files[path] else { throw LoadError.missingFile(path) }
            return Data(text.utf8)
        }
    }
}
