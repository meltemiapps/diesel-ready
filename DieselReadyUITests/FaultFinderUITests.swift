import XCTest

/// Opens every symptom in the Fault finder and follows a lesson link, and
/// checks that safety warnings come before the steps or causes they protect.
final class FaultFinderUITests: XCTestCase {

    private let symptoms = ["Exhaust smoke", "Won't start", "Overheating", "Stops suddenly", "Low oil pressure", "Not charging"]
    /// Symptoms that must open with a verbatim notice, by notice id.
    private let openingNotice = [
        "Overheating": "overheating-stop", "Low oil pressure": "oil-pressure-stop", "Won't start": "wet-exhaust-waterlock",
    ]
    private let stopCards = ["low-oil-pressure", "overheating", "water-ingress", "suspected-waterlock",
                             "fuel-spray", "smoke-or-fire", "shaft-seal-leak"]

    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testEverySymptomOpens() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-disclaimerAcceptedVersion", "1"]
        app.launch()

        app.tabBars.buttons["Faults"].tap()
        XCTAssertTrue(app.navigationBars["Fault finder"].waitForExistence(timeout: 5))
        snapshot(app, "faults-0-home")

        // The stop cards come first, before the symptom chips.
        let firstChip = app.buttons["Exhaust smoke"]
        XCTAssertTrue(firstChip.waitForExistence(timeout: 3))
        for id in stopCards {
            let card = app.descendants(matching: .any)["stop-card-\(id)"].firstMatch
            XCTAssertTrue(card.exists, "stop card \(id)")
            XCTAssertLessThan(card.frame.minY, firstChip.frame.minY, "stop card \(id) must come before the symptoms")
        }
        let lowOilCard = app.descendants(matching: .any)["stop-card-low-oil-pressure"].firstMatch
        XCTAssertTrue(lowOilCard.label.contains("Do not restart"))

        for (index, name) in symptoms.enumerated() {
            let chip = app.buttons[name]
            XCTAssertTrue(chip.waitForExistence(timeout: 3), "chip \(name)")
            bringChipsIntoView(app)
            chip.tap()
            let selected = expectation(for: NSPredicate(format: "isSelected == true"), evaluatedWith: chip)
            wait(for: [selected], timeout: 3)

            let heading = app.staticTexts.matching(NSPredicate(format: "label == %@", name))
                .matching(NSPredicate(format: "elementType == %d", XCUIElement.ElementType.staticText.rawValue))
            XCTAssertTrue(heading.firstMatch.waitForExistence(timeout: 3), "heading \(name)")

            let causes = app.staticTexts["Possible causes"]
            XCTAssertTrue(causes.waitForExistence(timeout: 3))
            XCTAssertFalse(app.staticTexts["Likely causes"].exists)
            if let noticeID = openingNotice[name] {
                let notice = app.descendants(matching: .any)["safety-notice-\(noticeID)"].firstMatch
                XCTAssertTrue(notice.exists, "\(name) should open with its safety notice")
                XCTAssertLessThan(notice.frame.minY, causes.frame.minY, "The notice must come before the causes")
                XCTAssertGreaterThan(notice.frame.minY, chip.frame.minY, "The notice belongs to the chosen symptom")
            }
            snapshot(app, "faults-\(index + 1)-\(name)")

            // Every symptom ends with the handbook reminder and at least one lesson link.
            let reminder = app.descendants(matching: .any)["fault-reminder"]
            scrollUntilVisible(reminder, in: app)
            XCTAssertTrue(reminder.exists, "\(name) should end with the reminder")
            XCTAssertTrue(reminder.label.contains("handbook"))
            XCTAssertTrue(app.staticTexts["Related lessons"].exists, "\(name) should link to lessons")
            if index == 0 { snapshot(app, "faults-1b-end") }
        }

        // Follow the last lesson link of the last symptom (on screen beside the reminder) and come back.
        let links = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Module '"))
        XCTAssertGreaterThan(links.count, 1, "Not charging should link to several lessons")
        let link = links.element(boundBy: links.count - 1)
        scrollUntilVisible(link, in: app)
        XCTAssertTrue(link.isHittable)
        let moduleNumber = link.label.split(separator: ",").first.map(String.init) ?? "Module"
        link.tap()
        let reader = app.navigationBars[moduleNumber]
        XCTAssertTrue(reader.waitForExistence(timeout: 5), "Lesson reader for \(moduleNumber)")
        snapshot(app, "faults-7-lesson")
        reader.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Fault finder"].waitForExistence(timeout: 3))
    }

    /// The lesson reader shows warnings before the first step.
    @MainActor
    func testLessonWarningsComeBeforeSteps() throws {
        for (lesson, notice) in [("m08-l02", "wet-exhaust-waterlock"), ("m02-l04", "high-pressure-fuel"),
                                 ("m04-l04", "oil-pressure-stop")] {
            let app = XCUIApplication()
            app.launchArguments += ["-disclaimerAcceptedVersion", "1", "-openLesson", lesson]
            app.launch()
            let warning = app.descendants(matching: .any)["safety-notice-\(notice)"].firstMatch
            XCTAssertTrue(warning.waitForExistence(timeout: 5), "\(lesson) shows \(notice)")
            let firstStep = app.descendants(matching: .any)["lesson-step-1"].firstMatch
            scrollUntilVisible(firstStep, in: app)
            XCTAssertTrue(firstStep.exists)
            XCTAssertTrue(firstStep.label.contains("Observe") || firstStep.label.contains("Owner") || firstStep.label.contains("Engineer"),
                          "\(lesson) step 1 should carry its action level")
            if warning.exists && warning.frame.height > 0 {
                XCTAssertLessThan(warning.frame.minY, firstStep.frame.minY, "\(lesson): the warning must come before step 1")
            }
            snapshot(app, "lesson-\(lesson)")
            app.terminate()
        }
    }

    /// Scrolls so the symptom chips are on screen: up to the top, then down past the stop cards.
    @MainActor
    private func bringChipsIntoView(_ app: XCUIApplication) {
        let chip = app.buttons["Exhaust smoke"]
        var tries = 0
        while !chip.isHittable && tries < 15 {
            // Above the chips are the stop cards; below them is the symptom detail.
            if chip.frame.minY > app.frame.midY { app.swipeUp() } else { app.swipeDown() }
            tries += 1
        }
        // Let any scroll deceleration finish, or the next tap only stops the scroll.
        Thread.sleep(forTimeInterval: 0.8)
    }

    @MainActor
    private func scrollUntilVisible(_ element: XCUIElement, in app: XCUIApplication) {
        var tries = 0
        while !(element.exists && element.isHittable) && tries < 12 {
            app.swipeUp()
            tries += 1
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
