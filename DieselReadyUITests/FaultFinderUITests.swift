import XCTest

/// Opens every symptom in the Fault finder and follows a lesson link.
final class FaultFinderUITests: XCTestCase {

    private let symptoms = ["Exhaust smoke", "Won't start", "Overheating", "Stops suddenly", "Low oil pressure", "Not charging"]
    private let stopFirst: Set<String> = ["Overheating", "Low oil pressure"]

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

        for (index, name) in symptoms.enumerated() {
            let chip = app.buttons[name]
            XCTAssertTrue(chip.waitForExistence(timeout: 3), "chip \(name)")
            scrollToTop(app)
            chip.tap()
            let selected = expectation(for: NSPredicate(format: "isSelected == true"), evaluatedWith: chip)
            wait(for: [selected], timeout: 3)

            let heading = app.staticTexts.matching(NSPredicate(format: "label == %@", name))
                .matching(NSPredicate(format: "elementType == %d", XCUIElement.ElementType.staticText.rawValue))
            XCTAssertTrue(heading.firstMatch.waitForExistence(timeout: 3), "heading \(name)")

            let causes = app.staticTexts["Likely causes"]
            XCTAssertTrue(causes.waitForExistence(timeout: 3))
            let stop = app.otherElements["stop-first"].exists ? app.otherElements["stop-first"] : app.staticTexts["stop-first"]
            if stopFirst.contains(name) {
                XCTAssertTrue(stop.exists, "\(name) should open with Stop the engine")
                XCTAssertTrue(stop.label.hasPrefix("Stop the engine"))
                XCTAssertLessThan(stop.frame.minY, causes.frame.minY, "Stop instruction must come before the causes")
            } else {
                XCTAssertFalse(stop.exists, "\(name) should not show a stop instruction")
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

    @MainActor
    private func scrollToTop(_ app: XCUIApplication) {
        var tries = 0
        while !app.buttons["Exhaust smoke"].isHittable && tries < 15 {
            app.swipeDown(velocity: .fast)
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
