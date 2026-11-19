import XCTest

/// Drives a mock test from the Quiz tab through results and "Retry missed".
final class QuizFlowUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testMockTestRunsToResultsAndRetry() throws {
        let app = XCUIApplication()
        // Skip the first-launch disclaimer for this test only.
        app.launchArguments += ["-disclaimerAcceptedVersion", "1"]
        app.launch()

        app.tabBars.buttons["Quiz"].tap()
        snapshot(app, "1-quiz-home")
        app.buttons["Start mock test"].tap()

        // Only module 1 has questions, so the shortfall is explained.
        let shortfall = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'questions are available so far'")).firstMatch
        XCTAssertTrue(shortfall.waitForExistence(timeout: 5))
        snapshot(app, "2-first-question")

        var answered = 0
        while answered < 40 {
            let optionA = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'A. '")).firstMatch
            guard optionA.waitForExistence(timeout: 3) else { break }
            optionA.tap()
            answered += 1
            if answered == 1 {
                // Let the tap's press animation settle so the screenshot shows final colours.
                _ = app.buttons["Next question"].waitForExistence(timeout: 3)
                Thread.sleep(forTimeInterval: 0.6)
                snapshot(app, "3-feedback")
            }

            let next = app.buttons["Next question"]
            let results = app.buttons["See results"]
            if results.exists {
                results.tap()
                break
            }
            XCTAssertTrue(next.waitForExistence(timeout: 3))
            next.tap()
        }
        XCTAssertEqual(answered, 17, "Mock test should use each of the 17 available questions once")

        let score = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH 'Your score'")).firstMatch
        XCTAssertTrue(score.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Results by module"].exists)
        snapshot(app, "4-results")

        let retry = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Retry missed'")).firstMatch
        if retry.exists {
            retry.tap()
            XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'A. '")).firstMatch.waitForExistence(timeout: 3))
            XCTAssertTrue(app.navigationBars["Retry missed"].exists)
            snapshot(app, "5-retry")
        }
    }

    @MainActor
    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
