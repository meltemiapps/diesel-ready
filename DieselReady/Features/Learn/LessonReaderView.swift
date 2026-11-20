import SwiftData
import SwiftUI

/// Reads one lesson: intro, optional diagram, numbered steps, caution, the
/// handbook reminder for hands-on lessons, and "Check your knowledge".
/// The lesson is marked complete when the reader scrolls to the end.
struct LessonReaderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query private var progressRecords: [LessonProgress]

    @State private var model: LessonReaderModel
    @State private var quizLaunch: QuizLaunch?

    init(module: Module, lessonID: Lesson.ID) {
        _model = State(initialValue: LessonReaderModel(module: module, lessonID: lessonID))
    }

    private var isCompleted: Bool {
        progressRecords.contains { $0.lessonID == model.lesson.id && $0.isCompleted }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                // Lazy so the end marker's onAppear fires only when it scrolls into view.
                LazyVStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    header
                        .id(ScrollAnchor.top)
                    Text(model.lesson.intro)
                        .font(.body)
                        .foregroundStyle(Theme.Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if let diagram = model.lesson.diagram, let view = LessonDiagram(diagram: diagram) {
                        view
                    }

                    steps

                    if let caution = model.lesson.caution {
                        Callout(kind: .caution, text: caution)
                    }

                    if model.lesson.handsOn {
                        HandbookReminder()
                    }

                    // End-of-lesson marker.
                    Color.clear
                        .frame(height: 1)
                        .accessibilityHidden(true)
                        .onAppear { model.didReachEnd(in: modelContext) }

                    footer(proxy: proxy)
                }
                // A fresh identity per lesson so the end marker fires again after "Next lesson".
                .id(model.lesson.id)
                .padding(Theme.Spacing.l)
                .frame(maxWidth: 700)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Theme.Palette.background)
        .navigationTitle("Module \(model.module.number)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.didOpen(in: modelContext) }
        .onChange(of: model.lesson.id) { model.didOpen(in: modelContext) }
        .quizCover($quizLaunch)
    }

    private enum ScrollAnchor: Hashable { case top }

    // MARK: Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s) {
            // Side by side normally; stacked at accessibility text sizes.
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.xs))
                : AnyLayout(HStackLayout())
            layout {
                Text("Module \(model.module.number) · Lesson \(model.positionText)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.Palette.secondaryText)
                if !dynamicTypeSize.isAccessibilitySize { Spacer() }
                if isCompleted {
                    Label("Read", systemImage: "checkmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Palette.success)
                }
            }
            ModuleProgressBar(fraction: model.positionFraction)
                .accessibilityLabel("Position in module")
                .accessibilityValue("Lesson \(model.index + 1) of \(model.lessonCount)")
            Text(model.lesson.title)
                .font(.screenTitle)
                .foregroundStyle(Theme.Palette.ink)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, Theme.Spacing.xs)
            Label("\(model.lesson.estimatedMinutes) min read", systemImage: "clock")
                .font(.footnote)
                .foregroundStyle(Theme.Palette.secondaryText)
        }
    }

    private var steps: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.l) {
            ForEach(Array(model.lesson.steps.enumerated()), id: \.offset) { index, step in
                StepRow(number: index + 1, step: step)
            }
        }
    }

    private func footer(proxy: ScrollViewProxy) -> some View {
        VStack(spacing: Theme.Spacing.m) {
            if let saveError = model.saveError {
                Callout(kind: .error, text: saveError)
            } else if isCompleted {
                Callout(kind: .success, text: "Lesson complete.")
            }

            if !model.questions.isEmpty {
                Button {
                    quizLaunch = QuizLaunch(mode: .lesson(model.lesson.id))
                } label: {
                    Label("Check your knowledge", systemImage: "checkmark.bubble")
                }
                .buttonStyle(.primary)
                .accessibilityHint("\(model.questions.count) questions on this lesson")
            }

            if let next = model.nextLesson {
                Button {
                    withAnimation { proxy.scrollTo(ScrollAnchor.top, anchor: .top) }
                    model.goToNext()
                } label: {
                    VStack(spacing: 2) {
                        Text("Next lesson")
                        Text(next.title).font(.footnote).multilineTextAlignment(.center)
                    }
                    .padding(.vertical, Theme.Spacing.xs)
                }
                .buttonStyle(.secondary)
            } else {
                Button("Back to lessons") { dismiss() }
                    .buttonStyle(.secondary)
            }
        }
        .padding(.top, Theme.Spacing.s)
    }
}

// MARK: - Pieces

private struct StepRow: View {
    let number: Int
    let step: Step

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
            NumberBadge("\(number)", fill: Theme.Palette.accent, foreground: Theme.Palette.onAccent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                if let title = step.title {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(Theme.Palette.ink)
                }
                Text(step.text)
                    .foregroundStyle(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number). \(step.title.map { "\($0). " } ?? "")\(step.text)")
    }
}

/// Shown at the end of every hands-on lesson.
struct HandbookReminder: View {
    static let text = "Engines differ. Always follow your engine manufacturer's handbook for procedures, settings and service intervals, and ask a qualified marine engineer if you are unsure."

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.m) {
            Image(systemName: "book.closed.fill")
                .foregroundStyle(Theme.Palette.link)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Check your handbook")
                    .font(.headline)
                    .foregroundStyle(Theme.Palette.ink)
                Text(Self.text)
                    .font(.callout)
                    .foregroundStyle(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .card()
        .accessibilityElement(children: .combine)
    }
}
