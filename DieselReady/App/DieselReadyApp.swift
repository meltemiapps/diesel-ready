import SwiftData
import SwiftUI

@main
struct DieselReadyApp: App {
    @State private var content = ContentStore()
    @State private var navigation = AppNavigation()

    init() {
        #if DEBUG
        // Debug builds only: `-resetDisclaimer YES` clears the saved acceptance so
        // UI tests can go through the real first-launch flow. (Passing the key
        // itself as a launch argument would override anything the app saves.)
        // Writing 0 rather than removing the key, which did not take effect
        // before the first read.
        if UserDefaults.standard.bool(forKey: "resetDisclaimer") {
            UserDefaults.standard.set(0, forKey: Disclaimer.acceptedVersionKey)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                #if DEBUG
                // Inside the environment modifiers below, so it can read them.
                .modifier(DebugLaunchActions())
                .task { openLessonFromLaunchArguments() }
                #endif
                .environment(content)
                .environment(navigation)
        }
        .modelContainer(for: ProgressSchema.models)
    }

    #if DEBUG
    /// Debug builds only: `-openLesson <lessonID>` opens a lesson at launch,
    /// for screenshots and manual testing from the command line.
    private func openLessonFromLaunchArguments() {
        guard let lessonID = UserDefaults.standard.string(forKey: "openLesson"),
              let module = content.library.module(containingLesson: lessonID),
              let lesson = module.lessons.first(where: { $0.id == lessonID })
        else { return }
        navigation.open(ProgressSummary.Position(module: module, lesson: lesson))
    }
    #endif
}

#if DEBUG
/// Debug builds only: `-seedDemoProgress YES` replaces any saved progress with a
/// realistic sample (modules 1 and 2 read, module 3 started, two quiz results),
/// so screenshots show the app in use. Never compiled into release builds.
private struct DebugLaunchActions: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    @Environment(ContentStore.self) private var content

    func body(content view: Content) -> some View {
        view.task { seedIfRequested() }
    }

    private func seedIfRequested() {
        guard UserDefaults.standard.bool(forKey: "seedDemoProgress") else { return }
        try? ProgressSchema.resetAll(in: modelContext)
        let modules = content.library.modules
        let start = Date.now.addingTimeInterval(-6 * 86_400)
        var step = 0.0
        for module in modules.prefix(2) {
            for lesson in module.lessons {
                step += 1
                let date = start.addingTimeInterval(step * 3_600)
                try? ProgressRecorder.markOpened(lessonID: lesson.id, moduleID: module.id, in: modelContext, now: date)
                try? ProgressRecorder.markCompleted(lessonID: lesson.id, moduleID: module.id, in: modelContext, now: date)
            }
        }
        if modules.count > 2 {
            let module = modules[2]
            try? ProgressRecorder.markCompleted(lessonID: module.lessons[0].id, moduleID: module.id, in: modelContext,
                                                now: .now.addingTimeInterval(-7_200))
            try? ProgressRecorder.markOpened(lessonID: module.lessons[1].id, moduleID: module.id, in: modelContext,
                                             now: .now.addingTimeInterval(-3_600))
        }
        modelContext.insert(QuizAttempt(mode: "module", scopeID: "m01", finishedAt: .now.addingTimeInterval(-90_000),
                                        correctCount: 17, totalCount: 20, missedQuestionIDs: []))
        modelContext.insert(QuizAttempt(mode: "quick", scopeID: nil, finishedAt: .now.addingTimeInterval(-5_000),
                                        correctCount: 9, totalCount: 10, missedQuestionIDs: []))
        try? modelContext.save()
    }
}
#endif
