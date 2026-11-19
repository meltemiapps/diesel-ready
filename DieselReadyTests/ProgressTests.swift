import Foundation
import SwiftData
import Testing
@testable import DieselReady

@Suite("Progress")
@MainActor
struct ProgressTests {

    // Two modules: m1 has lessons a, b, c; m2 has d, e.
    private let library = ContentLibrary(schemaVersion: 1, modules: [
        Self.module("m1", number: 1, lessons: ["a", "b", "c"]),
        Self.module("m2", number: 2, lessons: ["d", "e"]),
    ])

    private func date(_ minutes: Double) -> Date { Date(timeIntervalSince1970: minutes * 60) }

    private func done(_ id: String, at minutes: Double) -> LessonState {
        LessonState(lessonID: id, lastOpenedAt: date(minutes), completedAt: date(minutes))
    }

    private func opened(_ id: String, at minutes: Double) -> LessonState {
        LessonState(lessonID: id, lastOpenedAt: date(minutes), completedAt: nil)
    }

    // MARK: Summary

    @Test("Nothing started: continue offers the first lesson")
    func freshStart() {
        let summary = ProgressSummary(library: library, states: [])
        #expect(!summary.hasStarted)
        #expect(summary.completedModuleCount == 0)
        #expect(summary.fractionComplete == 0)
        #expect(summary.continuePosition?.lesson.id == "a")
    }

    @Test("Continue resumes the most recently opened unfinished lesson")
    func resumesLatestUnfinished() {
        let summary = ProgressSummary(library: library, states: [
            done("a", at: 1), opened("d", at: 5), opened("b", at: 3), done("c", at: 9),
        ])
        #expect(summary.continuePosition?.lesson.id == "d")
        #expect(summary.continuePosition?.module.id == "m2")
    }

    @Test("With nothing in progress, continue picks the first incomplete lesson in course order")
    func firstIncompleteInOrder() {
        let summary = ProgressSummary(library: library, states: [done("a", at: 1), done("d", at: 2)])
        #expect(summary.continuePosition?.lesson.id == "b")
    }

    @Test("A module counts as complete only when every lesson is read")
    func moduleCompletion() {
        let summary = ProgressSummary(library: library, states: [
            done("a", at: 1), done("b", at: 2), done("c", at: 3), done("d", at: 4),
        ])
        #expect(summary.isCompleted(module: library.modules[0]))
        #expect(!summary.isCompleted(module: library.modules[1]))
        #expect(summary.completedModuleCount == 1)
        #expect(summary.completedLessonCount(in: library.modules[1]) == 1)
        #expect(summary.fractionComplete == 0.8)
    }

    @Test("Everything read: no continue position")
    func allDone() {
        let summary = ProgressSummary(library: library, states: ["a", "b", "c", "d", "e"].enumerated().map {
            done($0.element, at: Double($0.offset))
        })
        #expect(summary.continuePosition == nil)
        #expect(summary.completedModuleCount == 2)
        #expect(summary.fractionComplete == 1)
    }

    @Test("Progress for lessons no longer in the content is ignored")
    func ignoresUnknownLessons() {
        let summary = ProgressSummary(library: library, states: [done("gone", at: 1), opened("old", at: 2)])
        #expect(summary.completedLessonCount == 0)
        #expect(summary.continuePosition?.lesson.id == "a")
    }

    // MARK: Recorder (SwiftData, in memory)

    private func makeContext() throws -> ModelContext {
        let schema = Schema(ProgressSchema.models)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        return ModelContext(container)
    }

    @Test("Opening then finishing a lesson keeps one record and the first completion date")
    func recorderLifecycle() throws {
        let context = try makeContext()
        try ProgressRecorder.markOpened(lessonID: "a", moduleID: "m1", in: context, now: date(1))
        try ProgressRecorder.markCompleted(lessonID: "a", moduleID: "m1", in: context, now: date(2))
        try ProgressRecorder.markOpened(lessonID: "a", moduleID: "m1", in: context, now: date(3))
        try ProgressRecorder.markCompleted(lessonID: "a", moduleID: "m1", in: context, now: date(4))

        let states = try ProgressRecorder.states(in: context)
        #expect(states.count == 1)
        #expect(states.first?.completedAt == date(2))
        #expect(states.first?.lastOpenedAt == date(4))
    }

    @Test("Reset removes all progress")
    func reset() throws {
        let context = try makeContext()
        try ProgressRecorder.markCompleted(lessonID: "a", moduleID: "m1", in: context)
        try ProgressRecorder.markOpened(lessonID: "b", moduleID: "m1", in: context)
        try ProgressSchema.resetAll(in: context)
        #expect(try ProgressRecorder.states(in: context).isEmpty)
    }

    // MARK: Reader model

    @Test("Reader shows position in module and advances to the next lesson")
    func readerModel() {
        let model = LessonReaderModel(module: library.modules[0], lessonID: "b")
        #expect(model.positionText == "2 / 3")
        #expect(model.hasNext)
        model.goToNext()
        #expect(model.lesson.id == "c")
        #expect(model.positionText == "3 / 3")
        #expect(!model.hasNext)
        model.goToNext()
        #expect(model.lesson.id == "c")
    }

    // MARK: Helpers

    private static func module(_ id: String, number: Int, lessons: [String]) -> Module {
        Module(id: id, number: number, title: id, summary: "", lessons: lessons.map {
            Lesson(id: $0, title: $0, estimatedMinutes: 5, intro: "", diagram: nil,
                   steps: [Step(title: nil, text: "x")], caution: nil, handsOn: false, reviewStatus: .draft)
        }, questions: [])
    }
}
