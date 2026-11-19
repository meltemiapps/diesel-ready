import Foundation
import SwiftData

// On-device progress. Stored with SwiftData in the app's private container and
// never synced or transmitted. Content is referenced by its stable JSON ids.

/// Per-lesson reading progress.
@Model
final class LessonProgress {
    @Attribute(.unique) var lessonID: String
    var moduleID: String
    var lastOpenedAt: Date
    var completedAt: Date?

    init(lessonID: String, moduleID: String, lastOpenedAt: Date = .now, completedAt: Date? = nil) {
        self.lessonID = lessonID
        self.moduleID = moduleID
        self.lastOpenedAt = lastOpenedAt
        self.completedAt = completedAt
    }

    var isCompleted: Bool { completedAt != nil }
}

/// One finished quiz.
@Model
final class QuizAttempt {
    /// Raw value of the quiz mode, e.g. "lesson", "module", "quick", "mock".
    var mode: String
    /// Lesson or module id for scoped quizzes; nil for quick quiz and mock test.
    var scopeID: String?
    var finishedAt: Date
    var correctCount: Int
    var totalCount: Int
    /// Ids of questions answered wrongly, for the review list.
    var missedQuestionIDs: [String]

    init(mode: String, scopeID: String?, finishedAt: Date = .now,
         correctCount: Int, totalCount: Int, missedQuestionIDs: [String]) {
        self.mode = mode
        self.scopeID = scopeID
        self.finishedAt = finishedAt
        self.correctCount = correctCount
        self.totalCount = totalCount
        self.missedQuestionIDs = missedQuestionIDs
    }
}

/// A lesson the learner has bookmarked.
@Model
final class Bookmark {
    @Attribute(.unique) var lessonID: String
    var createdAt: Date

    init(lessonID: String, createdAt: Date = .now) {
        self.lessonID = lessonID
        self.createdAt = createdAt
    }
}

enum ProgressSchema {
    static let models: [any PersistentModel.Type] = [LessonProgress.self, QuizAttempt.self, Bookmark.self]

    /// Deletes all progress, quiz attempts and bookmarks. The disclaimer
    /// acceptance is kept, so the learner is not asked to agree again.
    @MainActor
    static func resetAll(in context: ModelContext) throws {
        try context.delete(model: LessonProgress.self)
        try context.delete(model: QuizAttempt.self)
        try context.delete(model: Bookmark.self)
        try context.save()
    }
}
