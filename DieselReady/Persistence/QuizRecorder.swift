import Foundation
import SwiftData

/// Saves finished quizzes to SwiftData.
@MainActor
enum QuizRecorder {
    @discardableResult
    static func record(_ result: QuizResult, in context: ModelContext, now: Date = .now) throws -> QuizAttempt {
        let attempt = QuizAttempt(
            mode: result.mode.kind,
            scopeID: result.mode.scopeID,
            finishedAt: now,
            correctCount: result.correctCount,
            totalCount: result.totalCount,
            missedQuestionIDs: result.missedQuestionIDs
        )
        context.insert(attempt)
        try context.save()
        return attempt
    }
}
