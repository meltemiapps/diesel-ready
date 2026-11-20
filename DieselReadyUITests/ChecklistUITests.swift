import XCTest

/// The Checks tab: ticking and resetting items, VoiceOver labels and values,
/// the running-engine banner, and links to lessons and the Fault finder.
final class ChecklistUITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-disclaimerAcceptedVersion", "1"]
        app.launch()
        return app
    }

    @MainActor
    private func item(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.buttons["check-\(id)"]
    }

    @MainActor
    func testTickResetAndVoiceOverLabels() throws {
        let app = launch()
        let tabs = app.tabBars.buttons
        XCTAssertEqual(tabs.allElementsBoundByIndex.map(\.label), ["Learn", "Quiz", "Checks", "Faults", "About"])
        tabs["Checks"].tap()
        XCTAssertTrue(app.navigationBars["Engine checks"].waitForExistence(timeout: 5))

        // Pre-start is shown first, with no running-engine banner.
        XCTAssertTrue(app.buttons["Pre-start"].isSelected)
        XCTAssertFalse(app.descendants(matching: .any)["checks-running-banner"].exists)
        let progress = app.descendants(matching: .any)["checks-progress"].firstMatch
        XCTAssertEqual(progress.label, "0 of 16 checked")
        let reset = app.buttons["checks-reset"]
        XCTAssertFalse(reset.isEnabled, "nothing to reset yet")

        // VoiceOver reads the title, action level and detail, and the ticked state.
        let coolant = item(app, "pre-coolant")
        scrollTo(coolant, in: app)
        XCTAssertTrue(coolant.label.hasPrefix("Coolant level. Owner (handbook required)."), coolant.label)
        XCTAssertTrue(coolant.label.contains("never open a hot pressure cap"))
        XCTAssertEqual(coolant.value as? String, "Not ticked")
        XCTAssertGreaterThanOrEqual(coolant.frame.height, 44, "touch target")
        coolant.tap()
        XCTAssertEqual(coolant.value as? String, "Ticked")
        XCTAssertTrue(coolant.isSelected)

        let strainer = item(app, "pre-strainer")
        scrollTo(strainer, in: app)
        XCTAssertTrue(strainer.label.hasPrefix("Strainer clean and sealed. Observe."), strainer.label)
        strainer.tap()
        XCTAssertEqual(strainer.value as? String, "Ticked")

        // Tapping again unticks.
        strainer.tap()
        XCTAssertEqual(strainer.value as? String, "Not ticked")
        strainer.tap()
        XCTAssertEqual(progress.label, "2 of 16 checked")

        // Reset clears every tick.
        scrollUpTo(reset, in: app)
        XCTAssertTrue(reset.isEnabled)
        reset.tap()
        XCTAssertEqual(coolant.value as? String, "Not ticked")
        XCTAssertEqual(strainer.value as? String, "Not ticked")
        XCTAssertEqual(progress.label, "0 of 16 checked")
        XCTAssertFalse(reset.isEnabled)

        // Ticks are kept while switching lists, and reset clears both lists.
        coolant.tap()
        showList("Post-start", in: app)
        let exhaust = item(app, "post-exhaust-water")
        XCTAssertTrue(exhaust.waitForExistence(timeout: 3))
        exhaust.tap()
        XCTAssertEqual(exhaust.value as? String, "Ticked")
        showList("Pre-start", in: app)
        XCTAssertEqual(item(app, "pre-coolant").value as? String, "Ticked")
        scrollUpTo(reset, in: app)
        reset.tap()
        showList("Post-start", in: app)
        XCTAssertEqual(item(app, "post-exhaust-water").value as? String, "Not ticked")
    }

    @MainActor
    func testPostStartBannerComesFirstAndNoticeIsShown() throws {
        let app = launch()
        app.tabBars.buttons["Checks"].tap()
        showList("Post-start", in: app)

        let banner = app.descendants(matching: .any)["checks-running-banner"].firstMatch
        XCTAssertTrue(banner.waitForExistence(timeout: 3))
        XCTAssertTrue(banner.label.hasPrefix("Engine running: observe only"))
        let mnemonic = app.descendants(matching: .any)["checks-mnemonic"].firstMatch
        XCTAssertLessThan(banner.frame.minY, mnemonic.frame.minY, "the banner comes first")
        XCTAssertTrue(mnemonic.label.contains("This checklist covers Exhaust"))

        let exhaust = item(app, "post-exhaust-water")
        XCTAssertLessThan(banner.frame.minY, exhaust.frame.minY)
        XCTAssertTrue(exhaust.label.hasPrefix("Water from the exhaust. Observe."))
        // The overheating stop-engine notice appears with the exhaust check.
        let notice = app.descendants(matching: .any)["safety-notice-overheating-stop"].firstMatch
        scrollTo(notice, in: app)
        XCTAssertTrue(notice.exists)
        XCTAssertGreaterThan(notice.frame.minY, exhaust.frame.minY)
    }

    @MainActor
    func testLinksToLessonAndFaultFinder() throws {
        let app = launch()
        app.tabBars.buttons["Checks"].tap()

        // A check opens its lesson within the Checks tab.
        let lessonLink = app.buttons["check-lesson-pre-seacock"]
        scrollTo(lessonLink, in: app)
        XCTAssertTrue(lessonLink.label.contains("The raw water circuit"), lessonLink.label)
        lessonLink.tap()
        XCTAssertTrue(app.staticTexts["The raw water circuit: seacock and strainer"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()

        // The noise and smoke check opens Exhaust smoke in the Fault finder.
        showList("Post-start", in: app)
        let faultLink = app.buttons["check-fault-post-noise-smoke"]
        scrollTo(faultLink, in: app)
        XCTAssertEqual(faultLink.label, "Fault finder: Exhaust smoke")
        faultLink.tap()
        let chip = app.buttons["Exhaust smoke"]
        XCTAssertTrue(chip.waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Faults"].isSelected)
        let selected = expectation(for: NSPredicate(format: "isSelected == true"), evaluatedWith: chip)
        wait(for: [selected], timeout: 3)

        // Lesson 7.1 links to the checklists, and the checklist links back.
        app.tabBars.buttons["Checks"].tap()
        showList("Pre-start", in: app)
        let toLesson = app.buttons["checks-lesson-link"]
        scrollTo(toLesson, in: app)
        XCTAssertTrue(toLesson.label.contains("Daily pre-start checks"), toLesson.label)
        toLesson.tap()
        let toPostStart = app.buttons["lesson-checklist-post-start"]
        scrollTo(toPostStart, in: app)
        toPostStart.tap()
        let banner = app.descendants(matching: .any)["checks-running-banner"].firstMatch
        XCTAssertTrue(banner.waitForExistence(timeout: 3), "opens the post-start checklist")
        XCTAssertTrue(app.navigationBars["Engine checks"].exists, "back at the top of the Checks tab")
    }

    /// Taps a list in the segmented control, scrolling back up to it first.
    @MainActor
    private func showList(_ name: String, in app: XCUIApplication) {
        let segment = app.buttons[name]
        scrollUpTo(segment, in: app)
        segment.tap()
    }

    @MainActor
    private func scrollUpTo(_ element: XCUIElement, in app: XCUIApplication) {
        var tries = 0
        while !(element.exists && element.isHittable) && tries < 25 {
            app.swipeDown()
            tries += 1
        }
    }

    @MainActor
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        var tries = 0
        while !(element.exists && element.isHittable) && tries < 25 {
            app.swipeUp()
            tries += 1
        }
    }
}
