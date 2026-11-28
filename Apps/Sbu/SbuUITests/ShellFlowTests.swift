import XCTest

/// The notebook opens each tool full screen and goes back, every screen through the accessibility audit.
final class ShellFlowTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launch(tools: String) -> XCUIApplication {
        let app = XCUIApplication()
        // FASTLANE_SNAPSHOT: Level holds a fixed tilt, Moon a fixed date, Subscriptions made-up data.
        app.launchArguments += ["-AppleLanguages", "(it)", "-AppleLocale", "it_IT", "-FASTLANE_SNAPSHOT", "YES",
                                "-notebook.tools", tools]
        app.launch()
        XCTAssertTrue(app.staticTexts["Quaderno"].firstMatch.waitForExistence(timeout: 10), "the notebook did not open")
        return app
    }

    @MainActor
    func testOpensEachToolFromTheNotebook() throws {
        let app = launch(tools: "(level, moon, subscriptions)")
        try audit(app)
        // Each tool is audited as its own app's flow tests audit it: Subscriptions checks Dynamic Type by hand at AX5.
        let tools: [(String, String, XCUIAccessibilityAuditType)] = [
            ("level", "Livella", []), ("moon", "Illuminazione", []), ("subscriptions", "Abbonamenti", .dynamicType),
        ]
        for (tool, title, excluded) in tools {
            app.buttons["tool.\(tool)"].tap()
            let back = app.buttons["Quaderno"]
            XCTAssertTrue(back.waitForExistence(timeout: 10), "\(tool) did not open")
            XCTAssertTrue(app.staticTexts[title].firstMatch.waitForExistence(timeout: 10), "\(tool) shows no title")
            try audit(app, excluding: excluded)
            back.tap()
            XCTAssertTrue(app.buttons["tool.\(tool)"].waitForExistence(timeout: 5), "\(tool) did not close")
        }
    }

    @MainActor
    func testAddsAToolToAnEmptyNotebook() throws {
        let app = launch(tools: "()")
        try audit(app)
        app.buttons["Aggiungi strumenti"].tap()
        app.buttons["add.moon"].tap()
        // The sheet's Fine is the system's own bar button, which the audit reads as partly scaling.
        try audit(app, excluding: .dynamicType)
        app.buttons["Fine"].tap()
        XCTAssertTrue(app.buttons["tool.moon"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["tool.level"].exists)
    }

    /// The shell and the three tools, for the ticket and the QA: kept in the test result. Run it once
    /// with the simulator light and once dark (`xcrun simctl ui <device> appearance dark`).
    @MainActor
    func testScreenshots() {
        let app = launch(tools: "(level, moon, subscriptions)")
        let name = XCUIDevice.shared.appearance == .dark ? "dark" : "light"
        keep(app, "0-quaderno-\(name)")
        for (index, tool) in ["level", "moon", "subscriptions"].enumerated() {
            app.buttons["tool.\(tool)"].tap()
            _ = app.buttons["Quaderno"].waitForExistence(timeout: 10)
            sleep(1)
            keep(app, "\(index + 1)-\(tool)-\(name)")
            app.buttons["Quaderno"].tap()
            _ = app.buttons["tool.\(tool)"].waitForExistence(timeout: 5)
        }
    }

    @MainActor
    private func keep(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func audit(_ app: XCUIApplication, excluding extra: XCUIAccessibilityAuditType = []) throws {
        // Contrast as in the apps: the token pairs are checked by sync_tokens.py, the audit reads the grid under the text.
        try app.performAccessibilityAudit(for: XCUIAccessibilityAuditType.all.subtracting(.contrast).subtracting(extra)) { issue in
            guard Self.isSbuKitGridType(issue) == false else { return true }
            // The system search field's own placeholder (Subscriptions), drawn by iOS: as in that app's tests.
            if issue.auditType == .textClipped, issue.element?.elementType == .searchField { return true }
            XCTFail("\(issue.compactDescription): \(issue.element?.debugDescription ?? "no element")")
            return true
        }
    }

    /// As in the apps' flow tests: SbuKit sizes the figure in grid cells and draws the cartiglio in
    /// Plex Mono scaled by hand, on purpose; the audit also reads the cartiglio's tracking as clipping.
    private static func isSbuKitGridType(_ issue: XCUIAccessibilityAuditIssue) -> Bool {
        guard let label = issue.element?.label else { return false }
        let isCartiglio = label.hasPrefix("SBU ·")
        switch issue.auditType {
        case .dynamicType: return isCartiglio || label.contains(where: \.isNumber)
        case .textClipped: return isCartiglio
        default: return false
        }
    }
}
