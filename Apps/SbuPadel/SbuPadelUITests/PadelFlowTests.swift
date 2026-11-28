import XCTest

/// The iPhone screen driven as a person would: the rules before the first point, points, undo,
/// the sets on the scoreboard, the end of the match, and the audit.
@MainActor
final class PadelFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-resetMatch", "-AppleLanguages", "(it)", "-AppleLocale", "it_IT"]
        app.launch()
    }

    private func tap(_ button: XCUIElement, times: Int) {
        for _ in 0..<times { button.tap() }
    }

    func testPointsUndoAndRules() {
        let us = app.buttons["Punto a Noi"]
        XCTAssertTrue(us.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Annulla punto"].isEnabled)
        XCTAssertTrue(app.buttons["Vantaggi"].exists, "the rules are on screen before the first point")

        tap(us, times: 4)
        XCTAssertTrue((us.value as? String)?.hasPrefix("0, Game 1") == true, "\(String(describing: us.value))")
        XCTAssertTrue((app.buttons["Punto a Loro"].value as? String)?.hasSuffix("al servizio") == true)
        XCTAssertFalse(app.buttons["Vantaggi"].exists, "the rules give way to the court once the match starts")
        XCTAssertTrue(app.staticTexts["Punto d'oro"].exists)

        app.buttons["Annulla punto"].tap()
        XCTAssertTrue((us.value as? String)?.hasPrefix("40, Game 0") == true)
    }

    func testTheScoreboardKeepsEverySetAndTheMatchEndsWithTheResult() {
        let us = app.buttons["Punto a Noi"]
        XCTAssertTrue(us.waitForExistence(timeout: 10))
        tap(us, times: 24)
        let table = app.otherElements["Set"]
        XCTAssertTrue((table.value as? String)?.hasPrefix("Set 1: Noi 6, Loro 0. Set 2: Noi 0, Loro 0.") == true, "\(String(describing: table.value))")

        tap(us, times: 24)
        let result = app.otherElements["Partita vinta"]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        XCTAssertEqual(result.value as? String, "Set 2 a 0")
        XCTAssertFalse(us.exists, "the halves give way to the result")
    }

    func testAccessibilityAudit() throws {
        XCTAssertTrue(app.buttons["Punto a Noi"].waitForExistence(timeout: 10))
        try app.performAccessibilityAuditRetryingTimeouts(for: .all) { issue in
            issue.isCartiglio || issue.isGameCall
        }
    }

    func testAccessibilityAuditDuringAndAfterTheMatch() throws {
        let us = app.buttons["Punto a Noi"]
        XCTAssertTrue(us.waitForExistence(timeout: 10))
        tap(us, times: 26)
        try app.performAccessibilityAuditRetryingTimeouts(for: .all) { issue in
            issue.isCartiglio || issue.isGameCall
        }
        tap(us, times: 22)
        XCTAssertTrue(app.otherElements["Partita vinta"].waitForExistence(timeout: 5))
        try app.performAccessibilityAuditRetryingTimeouts(for: .all) { issue in
            issue.isCartiglio || issue.isGameCall
        }
    }
}
