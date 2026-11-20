import Observation
import SwiftUI

/// Tab selection and the Learn tab's navigation path, shared so that buttons
/// in one place (such as "Quick quiz" on the Learn tab) can move elsewhere.
@MainActor
@Observable
final class AppNavigation {
    enum Tab: Hashable {
        case learn, quiz, checks, faults, about
    }

    enum LearnRoute: Hashable {
        case module(Module.ID)
        case lesson(Lesson.ID)
    }

    var selectedTab: Tab = .learn
    var learnPath: [LearnRoute] = []
    /// The checklist shown on the Checks tab.
    var selectedChecklist = "pre-start"
    /// Goes up each time something asks to show a checklist, so the Checks tab
    /// can return to its root even when the same list is asked for again.
    private(set) var checklistRequests = 0
    /// A Fault finder symptom to open, set by links from other tabs.
    var requestedSymptom: Symptom.ID?

    /// Shows a checklist on the Checks tab.
    func showChecklist(_ id: Checklist.ID) {
        selectedChecklist = id
        checklistRequests += 1
        selectedTab = .checks
    }

    /// Opens a symptom on the Fault finder tab.
    func showSymptom(_ id: Symptom.ID) {
        requestedSymptom = id
        selectedTab = .faults
    }

    /// Opens a lesson with its module's lesson list underneath, so Back
    /// returns to the list rather than straight to the Learn tab.
    func open(_ position: ProgressSummary.Position) {
        selectedTab = .learn
        learnPath = [.module(position.module.id), .lesson(position.lesson.id)]
    }
}
