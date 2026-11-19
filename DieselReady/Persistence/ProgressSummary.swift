import Foundation

/// A plain, Sendable snapshot of one lesson's stored progress. Keeps the
/// progress rules independent of SwiftData so they are easy to unit-test.
struct LessonState: Sendable, Equatable {
    let lessonID: String
    let lastOpenedAt: Date
    let completedAt: Date?

    var isCompleted: Bool { completedAt != nil }
}

extension LessonState {
    init(_ record: LessonProgress) {
        self.init(lessonID: record.lessonID, lastOpenedAt: record.lastOpenedAt, completedAt: record.completedAt)
    }
}

/// Learner progress worked out from the content and the stored lesson states.
struct ProgressSummary: Sendable {
    let library: ContentLibrary
    private let states: [String: LessonState]

    init(library: ContentLibrary, states: [LessonState]) {
        self.library = library
        // Ids are unique in storage; if a duplicate ever appears, keep the more recent one.
        self.states = Dictionary(states.map { ($0.lessonID, $0) }) { a, b in
            a.lastOpenedAt >= b.lastOpenedAt ? a : b
        }
    }

    // MARK: Lessons

    func isCompleted(lesson lessonID: Lesson.ID) -> Bool {
        states[lessonID]?.isCompleted ?? false
    }

    func isStarted(lesson lessonID: Lesson.ID) -> Bool {
        states[lessonID] != nil
    }

    var totalLessonCount: Int { library.allLessons.count }

    var completedLessonCount: Int {
        library.allLessons.filter { isCompleted(lesson: $0.id) }.count
    }

    /// Share of all lessons completed, from 0 to 1.
    var fractionComplete: Double {
        totalLessonCount == 0 ? 0 : Double(completedLessonCount) / Double(totalLessonCount)
    }

    var hasStarted: Bool { !states.isEmpty }

    // MARK: Modules

    func completedLessonCount(in module: Module) -> Int {
        module.lessons.filter { isCompleted(lesson: $0.id) }.count
    }

    func isCompleted(module: Module) -> Bool {
        !module.lessons.isEmpty && completedLessonCount(in: module) == module.lessons.count
    }

    var completedModuleCount: Int {
        library.modules.filter { isCompleted(module: $0) }.count
    }

    // MARK: Continue

    struct Position: Sendable, Equatable {
        let module: Module
        let lesson: Lesson
    }

    /// The lesson "Continue lesson" opens:
    /// 1. the most recently opened lesson that is not yet complete; otherwise
    /// 2. the first incomplete lesson in course order; otherwise
    /// 3. nil, because everything is complete.
    var continuePosition: Position? {
        let opened = library.modules.flatMap { module in
            module.lessons.compactMap { lesson -> (Position, Date)? in
                guard let state = states[lesson.id], !state.isCompleted else { return nil }
                return (Position(module: module, lesson: lesson), state.lastOpenedAt)
            }
        }
        if let latest = opened.max(by: { $0.1 < $1.1 }) {
            return latest.0
        }
        for module in library.modules {
            if let lesson = module.lessons.first(where: { !isCompleted(lesson: $0.id) }) {
                return Position(module: module, lesson: lesson)
            }
        }
        return nil
    }
}
