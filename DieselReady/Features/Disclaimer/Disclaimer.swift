import Foundation

/// Versioned disclaimer text and acceptance record.
///
/// Acceptance is stored as the version number the learner agreed to. Bump
/// `currentVersion` whenever the wording below changes, and the first-launch
/// screen will be shown again.
enum Disclaimer {
    static let currentVersion = 1
    static let acceptedVersionKey = "disclaimerAcceptedVersion"

    static let subtitle = "Unofficial marine diesel engine study guide"

    static let points: [String] = [
        "This is an independent revision aid.",
        "It is not an official course.",
        "It awards no certificate.",
        "It is not affiliated with, endorsed by or connected to any training body, sailing association or engine manufacturer.",
        "Follow your engine handbook and a qualified engineer's advice.",
    ]

    static let checkboxLabel = "I understand this app is unofficial and for study purposes only"

    static func isAccepted(storedVersion: Int) -> Bool {
        storedVersion >= currentVersion
    }
}
