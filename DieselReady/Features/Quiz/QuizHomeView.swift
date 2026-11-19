import SwiftUI

/// Quiz tab placeholder. Quiz modes are built in Phase 3.
struct QuizHomeView: View {
    @Environment(ContentStore.self) private var content

    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Quizzes", systemImage: "checklist")
            } description: {
                Text("Lesson, module, quick quiz and mock test modes are on the way. \(content.library.allQuestions.count) questions are loaded so far.")
            }
            .background(Theme.Palette.background)
            .navigationTitle("Quiz")
        }
    }
}
