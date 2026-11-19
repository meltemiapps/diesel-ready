import Foundation

// Codable mirrors of the bundled JSON content.
//
// The JSON is platform-neutral (the Android app will read the same files), so
// field names are plain camelCase, enums are lowercase-hyphenated strings and
// nothing here relies on Swift-specific encoding. See docs/content-schema.md.

/// `Content/manifest.json`: lists the module files in display order.
struct ContentManifest: Codable, Sendable, Equatable {
    let schemaVersion: Int
    let modules: [String]
    /// File name of the fault finder content, relative to the content folder.
    let faults: String?
}

/// One module file, e.g. `Content/modules/01-how-a-diesel-engine-works.json`.
struct Module: Codable, Sendable, Identifiable, Hashable {
    let id: String
    let number: Int
    let title: String
    let summary: String
    let lessons: [Lesson]
    let questions: [Question]

    var estimatedMinutes: Int { lessons.reduce(0) { $0 + $1.estimatedMinutes } }

    func questions(forLesson lessonID: Lesson.ID) -> [Question] {
        questions.filter { $0.lessonId == lessonID }
    }
}

struct Lesson: Codable, Sendable, Identifiable, Hashable {
    let id: String
    let title: String
    let estimatedMinutes: Int
    let intro: String
    /// Optional SwiftUI-drawn diagram, identified by a platform-neutral key.
    let diagram: Diagram?
    let steps: [Step]
    let caution: String?
    /// True when the lesson describes hands-on work. The reader then ends the
    /// lesson with the reminder to follow the engine manufacturer's handbook.
    let handsOn: Bool
    let reviewStatus: ReviewStatus
}

struct Step: Codable, Sendable, Hashable {
    let title: String?
    let text: String
}

struct Diagram: Codable, Sendable, Hashable {
    /// Known kinds are drawn natively; unknown kinds are skipped so older app
    /// versions can read newer content.
    let kind: String
    let caption: String?
    /// Text drawn with the diagram, in the order the kind defines
    /// (panels left to right, or numbered parts).
    let labels: [DiagramLabel]
    /// Full description read by screen readers in place of the drawing.
    let description: String

    /// Number of labels each known kind draws. Unknown kinds are not checked.
    static let expectedLabelCounts: [String: Int] = [
        "compression-ignition": 3,
        "four-stroke-cycle": 4,
        "engine-layout": 7,
    ]
}

struct DiagramLabel: Codable, Sendable, Hashable {
    let title: String
    let detail: String?
}

struct Question: Codable, Sendable, Identifiable, Hashable {
    let id: String
    let moduleId: String
    let lessonId: String
    /// 1 (easy) to 3 (hard).
    let difficulty: Int
    let prompt: String
    /// Exactly four options.
    let options: [String]
    /// Zero-based index into `options`.
    let correctIndex: Int
    let explanation: String
    let reviewStatus: ReviewStatus

    var correctAnswer: String { options[correctIndex] }
}

enum ReviewStatus: String, Codable, Sendable {
    case draft
    case reviewed
}

/// Everything the app shows, decoded once at launch.
struct ContentLibrary: Sendable, Equatable {
    let schemaVersion: Int
    let modules: [Module]
    /// Fault finder content, or nil if the manifest lists none.
    let faults: FaultGuide?

    init(schemaVersion: Int, modules: [Module], faults: FaultGuide? = nil) {
        self.schemaVersion = schemaVersion
        self.modules = modules
        self.faults = faults
    }

    static let empty = ContentLibrary(schemaVersion: 0, modules: [])

    var allLessons: [Lesson] { modules.flatMap(\.lessons) }
    var allQuestions: [Question] { modules.flatMap(\.questions) }

    func module(withID id: Module.ID) -> Module? {
        modules.first { $0.id == id }
    }

    func module(containingLesson lessonID: Lesson.ID) -> Module? {
        modules.first { $0.lessons.contains { $0.id == lessonID } }
    }

    func lesson(withID lessonID: Lesson.ID) -> Lesson? {
        allLessons.first { $0.id == lessonID }
    }
}

// MARK: - Fault finder

/// `Content/faults.json`: the Fault finder tab.
struct FaultGuide: Codable, Sendable, Hashable {
    /// Shown above the symptom chips.
    let intro: String
    /// Shown at the end of every symptom: follow the handbook, ask an engineer.
    let reminder: String
    let symptoms: [Symptom]

    /// The symptoms the app must cover, by id.
    static let requiredSymptomIDs: Set<String> = [
        "exhaust-smoke", "wont-start", "overheating", "stops-suddenly", "low-oil-pressure", "not-charging",
    ]
    /// Symptoms where running on can damage the engine, so they must open
    /// with a "Stop the engine" instruction.
    static let stopFirstSymptomIDs: Set<String> = ["overheating", "low-oil-pressure"]
    static let stopFirstTitle = "Stop the engine"

    func symptom(withID id: Symptom.ID) -> Symptom? {
        symptoms.first { $0.id == id }
    }
}

struct Symptom: Codable, Sendable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    /// Shown before any diagnosis when running on could damage the engine.
    let stopFirst: StopInstruction?
    /// Most likely first.
    let causes: [FaultCause]
    /// In the order to do them.
    let checkFirst: [String]
    /// Lessons to read next. Every id must exist.
    let lessonIds: [String]
    let reviewStatus: ReviewStatus
}

struct StopInstruction: Codable, Sendable, Hashable {
    let title: String
    let text: String
}

struct FaultCause: Codable, Sendable, Hashable {
    let title: String
    let detail: String
}
