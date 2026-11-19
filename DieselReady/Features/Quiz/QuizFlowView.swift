import SwiftData
import SwiftUI

/// A request to start a quiz. A new id each time, so the same mode can be
/// launched again.
struct QuizLaunch: Identifiable {
    let id = UUID()
    let mode: QuizMode
}

extension View {
    /// Presents a quiz full screen whenever `launch` is set.
    func quizCover(_ launch: Binding<QuizLaunch?>) -> some View {
        modifier(QuizCoverModifier(launch: launch))
    }
}

private struct QuizCoverModifier: ViewModifier {
    @Environment(ContentStore.self) private var content
    @Binding var launch: QuizLaunch?

    func body(content view: Content) -> some View {
        view.fullScreenCover(item: $launch) { launch in
            QuizFlowView(mode: launch.mode, library: content.library)
        }
    }
}

/// Runs a quiz from first question to results, including "Retry missed".
struct QuizFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let library: ContentLibrary
    @State private var session: QuizSession
    @State private var saveError: String?
    @State private var confirmingExit = false

    init(mode: QuizMode, library: ContentLibrary) {
        self.library = library
        let selection = QuestionSelector.select(mode, from: library)
        _session = State(initialValue: QuizSession(mode: mode, selection: selection))
    }

    var body: some View {
        NavigationStack {
            Group {
                if session.isEmpty {
                    ContentUnavailableView {
                        Label("No questions yet", systemImage: "questionmark.circle")
                    } description: {
                        Text(session.selection.shortfallMessage ?? "There are no questions for this quiz yet.")
                    }
                } else if session.isFinished {
                    QuizResultsView(
                        result: session.result,
                        library: library,
                        saveError: saveError,
                        onRetryMissed: retryMissed,
                        onDone: { dismiss() }
                    )
                } else {
                    QuizQuestionView(session: session)
                }
            }
            .background(Theme.Palette.background)
            .navigationTitle(session.mode.title(in: library))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        if session.isFinished || session.answers.isEmpty {
                            dismiss()
                        } else {
                            confirmingExit = true
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("Close quiz")
                }
            }
            .confirmationDialog("End this quiz?", isPresented: $confirmingExit, titleVisibility: .visible) {
                Button("End quiz", role: .destructive) { dismiss() }
                Button("Keep going", role: .cancel) {}
            } message: {
                Text("Quizzes are saved when you finish them, so your answers so far will not be kept.")
            }
        }
        .onChange(of: session.isFinished) { _, finished in
            if finished { record() }
        }
    }

    private func record() {
        do {
            try QuizRecorder.record(session.result, in: modelContext)
            saveError = nil
        } catch {
            saveError = "This result could not be saved."
        }
    }

    private func retryMissed() {
        let ids = session.result.missedQuestionIDs
        guard !ids.isEmpty else { return }
        let mode = QuizMode.retry(ids)
        saveError = nil
        session = QuizSession(mode: mode, selection: QuestionSelector.select(mode, from: library))
    }
}
