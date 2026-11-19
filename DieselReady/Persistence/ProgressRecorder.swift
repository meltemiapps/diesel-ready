import Foundation
import SwiftData

/// Writes lesson progress to SwiftData.
@MainActor
enum ProgressRecorder {

    /// Records that a lesson was opened, creating its progress record if needed.
    static func markOpened(lessonID: String, moduleID: String, in context: ModelContext, now: Date = .now) throws {
        let record = try fetchOrInsert(lessonID: lessonID, moduleID: moduleID, in: context, now: now)
        record.lastOpenedAt = now
        try context.save()
    }

    /// Records that the learner reached the end of a lesson. The first
    /// completion date is kept if the lesson is read again.
    static func markCompleted(lessonID: String, moduleID: String, in context: ModelContext, now: Date = .now) throws {
        let record = try fetchOrInsert(lessonID: lessonID, moduleID: moduleID, in: context, now: now)
        record.lastOpenedAt = now
        if record.completedAt == nil {
            record.completedAt = now
        }
        try context.save()
    }

    static func states(in context: ModelContext) throws -> [LessonState] {
        try context.fetch(FetchDescriptor<LessonProgress>()).map(LessonState.init)
    }

    private static func fetchOrInsert(lessonID: String, moduleID: String,
                                      in context: ModelContext, now: Date) throws -> LessonProgress {
        var descriptor = FetchDescriptor<LessonProgress>(predicate: #Predicate { $0.lessonID == lessonID })
        descriptor.fetchLimit = 1
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let record = LessonProgress(lessonID: lessonID, moduleID: moduleID, lastOpenedAt: now)
        context.insert(record)
        return record
    }
}
