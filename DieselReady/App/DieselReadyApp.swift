import SwiftData
import SwiftUI

@main
struct DieselReadyApp: App {
    @State private var content = ContentStore()
    @State private var navigation = AppNavigation()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(content)
                .environment(navigation)
                #if DEBUG
                .task { openLessonFromLaunchArguments() }
                #endif
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
