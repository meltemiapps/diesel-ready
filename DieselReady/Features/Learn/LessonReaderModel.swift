import Foundation
import Observation
import SwiftData

/// View model for the lesson reader: which lesson is showing, its place in
/// the module, and recording when it is opened and finished.
@MainActor
@Observable
final class LessonReaderModel {
    let module: Module
    private(set) var index: Int
    /// Set when progress could not be saved, so the reader can say so.
    private(set) var saveError: String?

    init(module: Module, lessonID: Lesson.ID) {
        self.module = module
        self.index = module.lessons.firstIndex { $0.id == lessonID } ?? 0
    }

    var lesson: Lesson { module.lessons[index] }
    var lessonCount: Int { module.lessons.count }
    /// "3 / 5"
    var positionText: String { "\(index + 1) / \(lessonCount)" }
    var positionFraction: Double { Double(index + 1) / Double(max(lessonCount, 1)) }
    var hasNext: Bool { index + 1 < lessonCount }
    var nextLesson: Lesson? { hasNext ? module.lessons[index + 1] : nil }
    var questions: [Question] { module.questions(forLesson: lesson.id) }

    func goToNext() {
        guard hasNext else { return }
        index += 1
    }

    func didOpen(in context: ModelContext) {
        record { try ProgressRecorder.markOpened(lessonID: lesson.id, moduleID: module.id, in: context) }
    }

    func didReachEnd(in context: ModelContext) {
        record { try ProgressRecorder.markCompleted(lessonID: lesson.id, moduleID: module.id, in: context) }
    }

    private func record(_ action: () throws -> Void) {
        do {
            try action()
            saveError = nil
        } catch {
            saveError = "Your progress could not be saved."
        }
    }
}
