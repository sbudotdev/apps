import XCTest

/// The iPhone screen driven as a person would: points, undo, the rules locking, and the audit.
@MainActor
final class PadelFlowTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() async throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-resetMatch", "-AppleLanguages", "(it)", "-AppleLocale", "it_IT"]
        app.launch()
    }

    func testPointsUndoAndRules() {
        let us = app.buttons["Punto a Noi"]
        XCTAssertTrue(us.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Annulla punto"].isEnabled == false)

        for _ in 0..<4 { us.tap() }
        XCTAssertTrue((us.value as? String)?.hasPrefix("0, Game 1") == true, "\(String(describing: us.value))")
        XCTAssertTrue((app.buttons["Punto a Loro"].value as? String)?.hasSuffix("al servizio") == true)
        XCTAssertFalse(app.buttons["Vantaggi"].isEnabled)

        app.buttons["Annulla punto"].tap()
        XCTAssertTrue((us.value as? String)?.hasPrefix("40, Game 0") == true)
    }

    func testAccessibilityAudit() throws {
        XCTAssertTrue(app.buttons["Punto a Noi"].waitForExistence(timeout: 10))
        try app.performAccessibilityAuditRetryingTimeouts(for: .all) { issue in
            issue.isCartiglio || issue.isGameCall
        }
    }
}
