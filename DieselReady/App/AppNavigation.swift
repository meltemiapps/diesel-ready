import Observation
import SwiftUI

/// Tab selection and the Learn tab's navigation path, shared so that buttons
/// in one place (such as "Quick quiz" on the Learn tab) can move elsewhere.
@MainActor
@Observable
final class AppNavigation {
    enum Tab: Hashable {
        case learn, quiz, faults, about
    }

    enum LearnRoute: Hashable {
        case module(Module.ID)
        case lesson(Lesson.ID)
    }

    var selectedTab: Tab = .learn
    var learnPath: [LearnRoute] = []

    /// Opens a lesson with its module's lesson list underneath, so Back
    /// returns to the list rather than straight to the Learn tab.
    func open(_ position: ProgressSummary.Position) {
        selectedTab = .learn
        learnPath = [.module(position.module.id), .lesson(position.lesson.id)]
    }
}
