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
    /// File name of the shared safety notices, action levels and tags.
    var safety: String? = nil
    /// File name of the pre-start and post-start engine checklists.
    var checklists: String? = nil
    /// Version, review date and change log, shown on the About tab.
    var contentInfo: ContentInfo? = nil
}

/// Which version of the content is bundled, and where it is in review.
struct ContentInfo: Codable, Sendable, Hashable {
    /// For example "1.1".
    let version: String
    /// "draft" until a qualified marine engineer has approved the content,
    /// then "reviewed".
    let status: String
    /// Date of the latest technical review, as yyyy-MM-dd.
    let reviewDate: String
    /// "pending" until the content is approved, then "approved". Never a
    /// person's name or credentials.
    let engineerApproval: String

    /// Reviewed and approved by a qualified marine engineer.
    var isApproved: Bool { status == "reviewed" && engineerApproval == "approved" }
    /// Newest first.
    let changeLog: [ChangeLogEntry]

    /// `reviewDate` as a date, or nil if it is not a valid yyyy-MM-dd date.
    var reviewDateValue: Date? { Self.date(from: reviewDate) }

    static func date(from text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_GB_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        guard let date = formatter.date(from: text), formatter.string(from: date) == text else { return nil }
        return date
    }
}

struct ChangeLogEntry: Codable, Sendable, Hashable {
    let version: String
    /// yyyy-MM-dd.
    let date: String
    let summary: String
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
    /// Hazard warning for the lesson. Shown before the steps.
    let caution: String?
    /// True when the lesson describes a procedure (hands-on work). Every step
    /// then needs an action level, and the reader ends the lesson with the
    /// reminder to follow the engine manufacturer's handbook.
    let handsOn: Bool
    let reviewStatus: ReviewStatus
    /// What the expert reviewer should check. Never shown in the app.
    var reviewNote: String? = nil
    /// Shared safety notices (`safety.json`), shown before the steps.
    var safetyNoticeIds: [String]? = nil
    /// Installation types the lesson is written for (`safety.json` tags).
    var appliesTo: [String]? = nil
    /// Checklists (`checklists.json`) the lesson links to. Each one links back.
    var checklistIds: [String]? = nil

    var noticeIDs: [String] { safetyNoticeIds ?? [] }
    var tagIDs: [String] { appliesTo ?? [] }
    var checklistIDs: [String] { checklistIds ?? [] }

    /// A procedure with any step beyond observing. It must carry a warning,
    /// which the app shows before the first step.
    var isHazardousProcedure: Bool {
        handsOn && steps.contains { $0.action == .owner || $0.action == .engineer }
    }

    /// True when a warning (caution or notice) is shown before the steps.
    var hasWarningBeforeSteps: Bool {
        !(caution ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !noticeIDs.isEmpty
    }
}

struct Step: Codable, Sendable, Hashable {
    let title: String?
    let text: String
    /// Who should do this step. Required on every step of a hands-on lesson.
    var action: ActionLevel? = nil
}

/// Who a procedural step is for.
enum ActionLevel: String, Codable, Sendable, CaseIterable {
    /// Look and check only: nothing is opened, adjusted or dismantled.
    case observe
    /// Owner maintenance, following the engine handbook.
    case owner
    /// Only for a qualified engineer.
    case engineer
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
    static let labelCounts: [String: ClosedRange<Int>] = [
        "compression-ignition": 3...3,
        "four-stroke-cycle": 4...4,
        "engine-layout": 7...7,
        "flow": 2...7,
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
    /// What the expert reviewer should check. Never shown in the app.
    var reviewNote: String? = nil
    /// Shared safety notices shown with the answer feedback.
    var safetyNoticeIds: [String]? = nil
    /// Raw `QuestionCategory` values, e.g. "safety-critical".
    var categories: [String]? = nil

    var correctAnswer: String { options[correctIndex] }
    var noticeIDs: [String] { safetyNoticeIds ?? [] }

    func has(_ category: QuestionCategory) -> Bool {
        categories?.contains(category.rawValue) ?? false
    }
    var isSafetyCritical: Bool { has(.safetyCritical) }
    var isScenario: Bool { has(.scenario) }
}

/// How a question is used when building mock tests and reviewing content.
enum QuestionCategory: String, CaseIterable, Sendable {
    /// Tests knowledge that keeps people, the boat or the engine safe. Every
    /// question with a safety notice is safety-critical.
    case safetyCritical = "safety-critical"
    /// Built around a situation the learner has to respond to.
    case scenario
    /// A wrong answer is an unsafe action, so the explanation must say why.
    case unsafeDistractor = "unsafe-distractor"
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
    /// Safety notices, action levels and tags, or nil if the manifest lists none.
    let safety: SafetyGuide?
    /// Version and review status, or nil if the manifest has none.
    let info: ContentInfo?
    /// Pre-start and post-start checklists, or nil if the manifest lists none.
    let checks: ChecklistGuide?

    init(schemaVersion: Int, modules: [Module], faults: FaultGuide? = nil,
         safety: SafetyGuide? = nil, info: ContentInfo? = nil, checks: ChecklistGuide? = nil) {
        self.schemaVersion = schemaVersion
        self.modules = modules
        self.faults = faults
        self.safety = safety
        self.info = info
        self.checks = checks
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

// MARK: - Safety

/// `Content/safety.json`: wording shared by lessons, quiz feedback and the
/// Fault finder, so every surface says the same thing.
struct SafetyGuide: Codable, Sendable, Hashable {
    let notices: [SafetyNotice]
    let actionLevels: [ActionLevelInfo]
    let tags: [ApplicabilityTag]

    /// Notices the content must define (wet exhaust, high-pressure fuel, oil
    /// pressure, overheating).
    static let requiredNoticeIDs: [String] = [
        "wet-exhaust-waterlock", "high-pressure-fuel", "oil-pressure-stop", "overheating-stop",
    ]

    func notice(withID id: String) -> SafetyNotice? { notices.first { $0.id == id } }
    func tag(withID id: String) -> ApplicabilityTag? { tags.first { $0.id == id } }
    func info(for level: ActionLevel) -> ActionLevelInfo? { actionLevels.first { $0.id == level } }
}

/// A warning shown before steps, in quiz feedback or at the top of a symptom.
/// `text` may use `**bold**` for emphasis; nothing else is markup.
struct SafetyNotice: Codable, Sendable, Hashable, Identifiable {
    enum Level: String, Codable, Sendable {
        /// A stop-engine condition.
        case stop
        /// A hazard warning.
        case warning
    }

    let id: String
    let level: Level
    let title: String
    let text: String
}

struct ActionLevelInfo: Codable, Sendable, Hashable {
    let id: ActionLevel
    /// Shown on each step, e.g. "Owner (handbook required)".
    let label: String
    let description: String
}

/// An installation type a lesson applies to, e.g. common rail or keel cooling.
struct ApplicabilityTag: Codable, Sendable, Hashable, Identifiable {
    let id: String
    /// The choice this tag belongs to, e.g. "Fuel injection".
    let group: String
    let label: String
}

// MARK: - Fault finder

/// `Content/faults.json`: the Fault finder tab.
struct FaultGuide: Codable, Sendable, Hashable {
    /// Shown above everything else.
    let intro: String
    /// Shown at the end of every symptom: follow the handbook, ask an engineer.
    let reminder: String
    /// STOP / DO NOT RESTART / GET ASSISTANCE cards, shown before any symptom.
    let stopCards: [StopCard]
    let symptoms: [Symptom]

    /// The symptoms the app must cover, by id.
    static let requiredSymptomIDs: Set<String> = [
        "exhaust-smoke", "wont-start", "overheating", "stops-suddenly", "low-oil-pressure", "not-charging",
    ]
    /// Conditions that must each have a stop card, in display order.
    static let requiredStopCardIDs: [String] = [
        "low-oil-pressure", "overheating", "water-ingress", "suspected-waterlock",
        "fuel-spray", "smoke-or-fire", "shaft-seal-leak",
    ]
    /// Symptoms that must open with a given safety notice and stop card.
    static let requiredSymptomSafety: [String: RequiredSafety] = [
        "low-oil-pressure": RequiredSafety(noticeID: "oil-pressure-stop", stopCardID: "low-oil-pressure"),
        "overheating": RequiredSafety(noticeID: "overheating-stop", stopCardID: "overheating"),
        "wont-start": RequiredSafety(noticeID: "wet-exhaust-waterlock", stopCardID: "suspected-waterlock"),
    ]

    struct RequiredSafety: Sendable, Hashable {
        let noticeID: String
        let stopCardID: String
    }

    func symptom(withID id: Symptom.ID) -> Symptom? {
        symptoms.first { $0.id == id }
    }

    func stopCard(withID id: StopCard.ID) -> StopCard? {
        stopCards.first { $0.id == id }
    }
}

/// What to do at once when a dangerous condition appears.
struct StopCard: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let title: String
    let stop: String
    let doNotRestart: String
    let getAssistance: String
}

struct Symptom: Codable, Sendable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    /// Shared safety notices shown first, before anything else.
    var safetyNoticeIds: [String]? = nil
    /// Stop cards shown next, before the causes.
    var stopCardIds: [String]? = nil
    /// Not ranked: the app shows them as an unordered list.
    let possibleCauses: [FaultCause]
    /// In the order to do them.
    let checkFirst: [String]
    /// Lessons to read next. Every id must exist.
    let lessonIds: [String]
    let reviewStatus: ReviewStatus
    /// What the expert reviewer should check. Never shown in the app.
    var reviewNote: String? = nil

    var noticeIDs: [String] { safetyNoticeIds ?? [] }
    var cardIDs: [String] { stopCardIds ?? [] }
}

struct FaultCause: Codable, Sendable, Hashable {
    let title: String
    let detail: String
}

// MARK: - Checklists

/// `Content/checklists.json`: the Checks tab. Pre-start checks with the engine
/// off and post-start checks with it running, built on a memory aid.
struct ChecklistGuide: Codable, Sendable, Hashable {
    let mnemonic: Mnemonic
    /// Shown at the end of every checklist: follow the handbook.
    let reminder: String
    let checklists: [Checklist]

    /// Checklists the app must have, in display order.
    static let requiredChecklistIDs = ["pre-start", "post-start"]

    func checklist(withID id: Checklist.ID) -> Checklist? {
        checklists.first { $0.id == id }
    }

    var allItems: [ChecklistItem] { checklists.flatMap(\.items) }
}

/// A mnemonic whose letters match the checklist sections that carry a letter.
struct Mnemonic: Codable, Sendable, Hashable {
    let name: String
    let summary: String
    let letters: [MnemonicLetter]
}

struct MnemonicLetter: Codable, Sendable, Hashable {
    let letter: String
    let word: String
}

struct Checklist: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let title: String
    /// For example "Engine off".
    let subtitle: String
    let intro: String
    /// Shown first when the engine is running, e.g. "observe only".
    var banner: String? = nil
    /// True for checks made with the engine running. Every item must then be
    /// observe only, and the banner is required.
    let engineRunning: Bool
    /// The lesson that teaches these checks. It must link back.
    let lessonId: String
    let sections: [ChecklistSection]
    let reviewStatus: ReviewStatus
    /// What the expert reviewer should check. Never shown in the app.
    var reviewNote: String? = nil

    var items: [ChecklistItem] { sections.flatMap(\.items) }
}

struct ChecklistSection: Codable, Sendable, Hashable, Identifiable {
    let id: String
    /// The memory-aid letter this section stands for, if any.
    var letter: String? = nil
    let title: String
    let items: [ChecklistItem]
}

struct ChecklistItem: Codable, Sendable, Hashable, Identifiable {
    let id: String
    let title: String
    let detail: String
    /// Observe or owner. Checklists never include engineer-only work.
    let action: ActionLevel
    /// The lesson to read for this check. Must exist.
    let lessonId: String
    /// Shared safety notices that apply, referenced rather than copied.
    var safetyNoticeIds: [String]? = nil
    /// A Fault finder symptom to open if the check finds a problem.
    var symptomId: String? = nil
    let reviewStatus: ReviewStatus

    var noticeIDs: [String] { safetyNoticeIds ?? [] }
}
