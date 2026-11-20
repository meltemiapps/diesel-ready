import UIKit
import XCTest

/// Accessibility checks that run in the normal test suite.
final class AccessibilityUITests: XCTestCase {

    /// The largest accessibility text size, as a launch argument value.
    static let largestTextSize = UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue

    override func setUp() {
        continueAfterFailure = false
    }

    /// The disclaimer must be usable at the largest accessibility text size:
    /// tick the box, agree, and reach the Learn tab.
    @MainActor
    func testDisclaimerCanBeAcceptedAtLargestTextSize() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-resetDisclaimer", "YES",
            "-UIPreferredContentSizeCategoryName", Self.largestTextSize,
        ]
        app.launch()

        let checkbox = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'I understand'")).firstMatch
        XCTAssertTrue(checkbox.waitForExistence(timeout: 5))
        scrollTo(checkbox, in: app)
        XCTAssertEqual(checkbox.value as? String, "Not ticked")
        checkbox.tap()
        XCTAssertEqual(checkbox.value as? String, "Ticked")

        let agree = app.buttons["Agree and continue"]
        scrollTo(agree, in: app)
        XCTAssertTrue(agree.isEnabled)
        agree.tap()
        XCTAssertTrue(app.tabBars.buttons["Learn"].waitForExistence(timeout: 5),
                      "Accepting the disclaimer should open the app")
    }

    /// At the largest text size, each new quiz question opens scrolled to the top.
    @MainActor
    func testNextQuestionStartsAtTopAtLargestTextSize() throws {
        let app = XCUIApplication()
        app.launchArguments += [
            "-disclaimerAcceptedVersion", "1",
            "-UIPreferredContentSizeCategoryName", Self.largestTextSize,
        ]
        app.launch()
        app.tabBars.buttons["Quiz"].tap()
        let start = app.buttons["Start quick quiz"]
        scrollTo(start, in: app)
        start.tap()

        let option = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'A. '")).firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5))
        scrollTo(option, in: app)
        option.tap()
        let next = app.buttons["Next question"]
        XCTAssertTrue(next.waitForExistence(timeout: 3))
        scrollTo(next, in: app)
        next.tap()

        let position = app.staticTexts["Question 2 of 10"]
        XCTAssertTrue(position.waitForExistence(timeout: 3))
        XCTAssertTrue(position.isHittable, "The second question should open at the top")
    }

    /// Apple's automated accessibility audit on each tab: contrast, element
    /// descriptions, hit regions, clipped text and Dynamic Type support.
    @MainActor
    func testTabsPassAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-disclaimerAcceptedVersion", "1"]
        app.launch()
        for tab in ["Learn", "Quiz", "Faults", "About"] {
            app.tabBars.buttons[tab].tap()
            if tab == "Faults" { app.buttons["Overheating"].tap() }
            let tabBarFrame = app.tabBars.firstMatch.frame
            try app.performAccessibilityAudit { issue in
                // System-drawn tab bar items are outside the app's control.
                if let element = issue.element, element.elementType == .tabBar || element.elementType == .tab {
                    return true
                }
                // Contrast reports with no element come from system-drawn translucent
                // layers (the floating tab bar over scrolling content). Every colour
                // pair the app draws is checked against WCAG AA in ThemeContrastTests.
                if issue.auditType == .contrast && issue.element == nil {
                    return true
                }
                // Text that has scrolled underneath the translucent tab bar is measured
                // against the blurred glass, not the background it is designed for.
                if issue.auditType == .contrast, let frame = issue.element?.frame, frame.intersects(tabBarFrame) {
                    return true
                }
                let element = issue.element
                print("AUDIT [\(tab)] \(issue.detailedDescription) | label=\(element?.label ?? "nil") type=\(element?.elementType.rawValue ?? 0) frame=\(element?.frame ?? .zero)")
                return false
            }
        }
    }

    @MainActor
    private func scrollTo(_ element: XCUIElement, in app: XCUIApplication) {
        var tries = 0
        while !element.isHittable && tries < 15 {
            app.swipeUp()
            tries += 1
        }
    }
}
