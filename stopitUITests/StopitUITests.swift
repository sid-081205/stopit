import XCTest

final class StopitUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing-reset"]
        app.launch()
    }

    func testCompletingOnboarding() {
        completeOnboarding()
        XCTAssertTrue(app.staticTexts["stopit"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["log urge"].exists)
    }

    func testLoggingAnUrge() {
        completeOnboarding()
        app.buttons["log urge"].tap()
        XCTAssertTrue(app.staticTexts["urge logged"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["reason morning"].waitForExistence(timeout: 2))
        app.buttons["reason morning"].tap()
        XCTAssertTrue(app.staticTexts["urge · morning"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["1"].firstMatch.exists)
    }

    func testLoggingAnOccurrence() {
        completeOnboarding()
        app.buttons["log occurrence"].tap()
        XCTAssertTrue(app.staticTexts["logged"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["1 of 7 this week"].waitForExistence(timeout: 2))
    }

    func testOpeningAndEditingHistory() {
        completeOnboarding()
        app.buttons["log urge"].tap()
        app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'urge,'")
        ).firstMatch.tap()

        XCTAssertTrue(app.navigationBars["edit entry"].waitForExistence(timeout: 2))
        app.segmentedControls.buttons["did it"].tap()
        app.buttons["save event"].tap()
        XCTAssertTrue(
            app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH 'did it,'")
            ).firstMatch.waitForExistence(timeout: 2)
        )
    }

    func testDeletingAnEvent() {
        completeOnboarding()
        app.buttons["log urge"].tap()
        app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'urge,'")
        ).firstMatch.tap()
        app.buttons["delete event"].tap()
        app.sheets.buttons["delete event"].tap()

        XCTAssertTrue(app.staticTexts["your entries will appear here."].waitForExistence(timeout: 2))
    }

    func testChangingWeeklyTarget() {
        completeOnboarding()
        app.buttons["settings"].tap()
        let input = app.textFields["weekly target input"]
        XCTAssertTrue(input.waitForExistence(timeout: 2))
        input.tap()
        input.press(forDuration: 1)
        app.menuItems["select all"].tap()
        input.typeText("4")
        app.buttons["save settings"].tap()

        XCTAssertTrue(app.staticTexts["0 of 4 this week"].waitForExistence(timeout: 2))
    }

    func testSwitchingInsightRanges() {
        completeOnboarding()
        app.tabBars.buttons["insights"].tap()
        let selector = app.segmentedControls["insight range"]
        XCTAssertTrue(selector.waitForExistence(timeout: 2))
        selector.buttons["30 days"].tap()
        XCTAssertTrue(selector.buttons["30 days"].isSelected)
        selector.buttons["90 days"].tap()
        XCTAssertTrue(selector.buttons["90 days"].isSelected)
    }

    private func completeOnboarding() {
        let field = app.textFields["habit name"]
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.typeText("snacking")
        app.buttons["get started"].tap()
        XCTAssertTrue(app.buttons["log urge"].waitForExistence(timeout: 2))
    }
}
