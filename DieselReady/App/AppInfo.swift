import Foundation

/// Fixed app facts, links and legal wording shared by About, Privacy and the disclaimer.
enum AppInfo {
    static let name = "Diesel Ready"
    static let studio = "Meltemi Apps"
    static let supportEmail = "support@meltemiapps.co.uk"

    // Force-unwraps are safe: these are compile-time constant, valid URLs.
    static let websiteURL = URL(string: "https://meltemiapps.co.uk/diesel-ready/")!
    static let privacyURL = URL(string: "https://meltemiapps.co.uk/diesel-ready/privacy/")!
    static let repositoryURL = URL(string: "https://github.com/meltemiapps/diesel-ready")!
    static let codeLicenceURL = URL(string: "https://github.com/meltemiapps/diesel-ready/blob/main/LICENSE")!
    static let contentLicenceURL = URL(string: "https://github.com/meltemiapps/diesel-ready/blob/main/CONTENT-LICENSE")!
    static let supportEmailURL = URL(string: "mailto:support@meltemiapps.co.uk?subject=Diesel%20Ready")!

    static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    // MARK: Statements

    static let unofficialStatement = """
        Diesel Ready is an independent, unofficial study guide made by Meltemi Apps. \
        It is not an official course and it awards no certificate. It is not affiliated \
        with, endorsed by or connected to any training organisation, sailing association, \
        awarding body or engine manufacturer.
        """

    static let privacySummary: [String] = [
        "No account is needed.",
        "Your progress stays on this device.",
        "No ads, analytics or tracking.",
        "Deleting the app removes all of its data.",
    ]

    static let safetyNotice = """
        The content is general guidance for leisure boaters. Engines differ, so always \
        follow your engine manufacturer's handbook and the advice of a qualified marine \
        engineer. Never work on an engine while it is running unless a procedure \
        specifically requires it.
        """

    static let trademarkNotice = """
        Any third-party names belong to their respective owners and are used only to \
        describe subject matter.
        """
}

/// The full in-app privacy policy. Kept in step with docs/site/diesel-ready/privacy/.
enum PrivacyPolicy {
    static let lastUpdated = "19 November 2026"

    struct Section: Identifiable {
        let heading: String
        let body: String
        var id: String { heading }
    }

    static let sections: [Section] = [
        Section(
            heading: "Who we are",
            body: """
                Diesel Ready is made by Meltemi Apps, an independent app studio in the \
                United Kingdom. You can contact us at support@meltemiapps.co.uk.
                """
        ),
        Section(
            heading: "The short version",
            body: """
                Diesel Ready does not collect any personal data. It has no accounts, \
                no ads, no analytics, no crash reporting and no tracking, and it makes \
                no network connections.
                """
        ),
        Section(
            heading: "What is stored on your device",
            body: """
                To remember where you are, the app stores your lesson progress, quiz \
                results, bookmarks and the fact that you accepted the disclaimer. This \
                information is kept only on your device, inside the app's own storage. \
                It is never sent to us or to anyone else, and we cannot see it.
                """
        ),
        Section(
            heading: "Backups",
            body: """
                If you use your device's own backup service, such as iCloud Backup, \
                the app's on-device data may be included in that backup under your \
                account with that service. Meltemi Apps has no access to it.
                """
        ),
        Section(
            heading: "Deleting your data",
            body: """
                You can clear your progress at any time with Reset progress on the \
                About tab. Deleting the app removes all of its data from your device.
                """
        ),
        Section(
            heading: "Your rights under UK GDPR",
            body: """
                Because we do not collect or process any personal data about you, we \
                hold nothing that we could access, correct, export or erase on your \
                behalf. If you have a question about privacy, email us and we will \
                reply. You also have the right to complain to the Information \
                Commissioner's Office (ico.org.uk).
                """
        ),
        Section(
            heading: "Children",
            body: """
                The app is suitable for all ages and collects no data from anyone, \
                including children.
                """
        ),
        Section(
            heading: "Unofficial and unaffiliated",
            body: AppInfo.unofficialStatement
        ),
        Section(
            heading: "Changes to this policy",
            body: """
                If this policy changes, the updated version will be published in the \
                app and at meltemiapps.co.uk/diesel-ready/privacy/ with a new date.
                """
        ),
    ]
}
