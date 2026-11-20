import XCTest

/// Screenshot capture for the accessibility audit and the App Store.
///
/// Skipped in normal test runs. `scripts/capture-screenshots.sh` runs these with
/// `TEST_RUNNER_CAPTURE_SCREENSHOTS=1` after setting the simulator's appearance
/// and text size, then exports the attachments into `docs/screenshots/`.
final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["CAPTURE_SCREENSHOTS"] == "1",
                          "Screenshot capture runs only from scripts/capture-screenshots.sh")
        continueAfterFailure = true
    }

    // MARK: - Audit: every screen

    @MainActor
    func testAuditScreens() throws {
        // First launch: the disclaimer.
        var app = launch(["-resetDisclaimer", "YES"], acceptDisclaimer: false)
        pages(app, "01-disclaimer", count: 3)
        scrollTo(app.buttons["Agree and continue"], in: app)
        let checkbox = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'I understand'")).firstMatch
        scrollTo(checkbox, in: app)
        if (checkbox.value as? String) != "Ticked" { checkbox.tap() }
        scrollTo(app.buttons["Agree and continue"], in: app)
        app.buttons["Agree and continue"].tap()

        // Learn tab, module and lesson list.
        XCTAssertTrue(tab(app, "Learn").waitForExistence(timeout: 5))
        pages(app, "02-learn", count: 3)
        app.terminate()

        app = launch(["-openLesson", "m01-l02"])
        pages(app, "04-lesson-four-stroke", count: 4)
        app.navigationBars.buttons.firstMatch.tap()
        pages(app, "03-module-detail", count: 2)
        app.terminate()

        app = launch(["-openLesson", "m03-l02"])
        pages(app, "05-lesson-flow-diagram", count: 3)
        app.terminate()

        // A short lesson quiz from the end of a hands-on lesson, through to results.
        app = launch(["-openLesson", "m01-l04"])
        let check = app.buttons["Check your knowledge"]
        scrollTo(check, in: app)
        snap(app, "06-lesson-end-handbook")
        check.tap()
        _ = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'A. '")).firstMatch.waitForExistence(timeout: 5)
        snap(app, "07-quiz-question")
        var answered = 0
        while answered < 6 {
            let option = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'B. '")).firstMatch
            guard option.waitForExistence(timeout: 3) else { break }
            scrollTo(option, in: app)
            option.tap()
            answered += 1
            Thread.sleep(forTimeInterval: 0.6)
            if answered == 1 { snap(app, "08-quiz-feedback") }
            if app.buttons["See results"].exists {
                scrollTo(app.buttons["See results"], in: app)
                app.buttons["See results"].tap()
                break
            }
            let next = app.buttons["Next question"]
            scrollTo(next, in: app)
            next.tap()
        }
        _ = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Your score'")).firstMatch.waitForExistence(timeout: 5)
        pages(app, "09-quiz-results", count: 3)
        app.terminate()

        // Quiz tab.
        app = launch()
        tab(app, "Quiz").tap()
        pages(app, "10-quiz-home", count: 3)

        // Fault finder.
        tab(app, "Faults").tap()
        snap(app, "11-faults-home")
        let overheating = app.buttons["Overheating"]
        scrollTo(overheating, in: app)
        overheating.tap()
        Thread.sleep(forTimeInterval: 0.5)
        pages(app, "12-faults-overheating", count: 4)

        // About, privacy policy and the reset confirmation.
        tab(app, "About").tap()
        pages(app, "13-about", count: 4)
        scrollUp(app)
        let privacy = app.buttons["Privacy policy"]
        scrollTo(privacy, in: app)
        privacy.tap()
        pages(app, "15-privacy-policy", count: 3)
        app.navigationBars.buttons.firstMatch.tap()
        let reset = app.buttons["Reset progress"]
        scrollTo(reset, in: app)
        reset.tap()
        Thread.sleep(forTimeInterval: 0.6)
        snap(app, "14-reset-confirmation")
    }

    // MARK: - App Store screenshots

    @MainActor
    func testAppStoreScreens() throws {
        var app = launch(["-seedDemoProgress", "YES"])
        XCTAssertTrue(app.staticTexts["Your progress"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1)
        snap(app, "1-learn")
        app.terminate()

        app = launch(["-openLesson", "m01-l02"])
        Thread.sleep(forTimeInterval: 1)
        snap(app, "2-lesson-diagram")
        app.terminate()

        // A question answered correctly: try questions until one is.
        app = launch()
        tab(app, "Quiz").tap()
        app.buttons["Start quick quiz"].tap()
        var captured = false
        for _ in 0..<10 {
            let option = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'B. '")).firstMatch
            guard option.waitForExistence(timeout: 3) else { break }
            option.tap()
            Thread.sleep(forTimeInterval: 1)
            if app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Correct.'")).firstMatch.exists {
                snap(app, "3-quiz-feedback")
                captured = true
                break
            }
            let next = app.buttons["Next question"]
            guard next.exists else { break }
            next.tap()
        }
        XCTAssertTrue(captured, "No correctly answered question to capture")
        app.terminate()

        app = launch()
        tab(app, "Faults").tap()
        app.buttons["Overheating"].tap()
        Thread.sleep(forTimeInterval: 0.8)
        // Bring the chosen symptom and its stop-engine warning to the top of the screen.
        let notice = app.descendants(matching: .any)["safety-notice-overheating-stop"].firstMatch
        var tries = 0
        while notice.exists && notice.frame.minY > app.frame.height * 0.3 && tries < 12 {
            app.swipeUp(velocity: .slow)
            tries += 1
        }
        while notice.exists && notice.frame.minY < app.frame.height * 0.12 && tries < 20 {
            app.swipeDown(velocity: .slow)
            tries += 1
        }
        Thread.sleep(forTimeInterval: 0.8)
        snap(app, "4-fault-finder")

        tab(app, "About").tap()
        Thread.sleep(forTimeInterval: 0.8)
        snap(app, "5-about")
    }

    // MARK: - Helpers

    /// A tab button. On iPhone it is in the tab bar; on iPad the tabs sit at
    /// the top of the screen and are exposed as ordinary buttons.
    @MainActor
    private func tab(_ app: XCUIApplication, _ name: String) -> XCUIElement {
        let inTabBar = app.tabBars.buttons[name]
        return inTabBar.exists ? inTabBar : app.buttons[name].firstMatch
    }

    @MainActor
    private func launch(_ arguments: [String] = [], acceptDisclaimer: Bool = true) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = (acceptDisclaimer ? ["-disclaimerAcceptedVersion", "1"] : []) + arguments
        app.launch()
        Thread.sleep(forTimeInterval: 1.5)
        return app
    }

    /// Captures the screen, then scrolls and captures again, `count` times in all.
    @MainActor
    private func pages(_ app: XCUIApplication, _ name: String, count: Int) {
        for page in 1...count {
            if page > 1 {
                app.swipeUp()
                Thread.sleep(forTimeInterval: 0.6)
            }
            snap(app, count == 1 ? name : "\(name)-\(page)")
        }
    }

    @MainActor
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        var tries = 0
        while !(element.exists && element.isHittable) && tries < 25 {
            app.swipeUp()
            tries += 1
        }
        Thread.sleep(forTimeInterval: 0.6)
    }

    @MainActor
    private func scrollUp(_ app: XCUIApplication) {
        for _ in 0..<8 { app.swipeDown(velocity: .fast) }
        Thread.sleep(forTimeInterval: 0.6)
    }

    @MainActor
    private func snap(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
