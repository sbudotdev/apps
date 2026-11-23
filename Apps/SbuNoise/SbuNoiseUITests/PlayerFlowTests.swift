import XCTest

/// Drives the player like a person would, then audits the screen for accessibility.
final class PlayerFlowTests: XCTestCase {
    @MainActor
    func testPlayNextInfoAndAudit() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(it)", "-AppleLocale", "it_IT", "-lastSoundID", "noise.white", "-lastCategory", "sounds"]
        app.launchEnvironment["SBU_NOISE_FILE"] = "ui-\(UUID().uuidString).json"
        app.launch()

        XCTAssertTrue(figure(app, "Rumore bianco").waitForExistence(timeout: 5))
        app.buttons["Riproduci"].tap()
        XCTAssertTrue(app.buttons["Pausa"].waitForExistence(timeout: 2))

        app.buttons["Successivo"].tap()
        XCTAssertTrue(figure(app, "Rumore rosa").waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Pausa"].exists, "Changing sound keeps playing")

        app.buttons["Aggiungi ai preferiti"].tap()
        XCTAssertTrue(app.buttons["Togli dai preferiti"].exists)

        try app.auditAccessibility()

        app.buttons["Informazioni"].tap()
        XCTAssertTrue(app.staticTexts["Generato in tempo reale"].waitForExistence(timeout: 2))
        try app.auditAccessibility()
        app.buttons["Fine"].tap()

        app.buttons["Categorie"].tap()
        app.buttons["Preferiti"].tap()
        XCTAssertTrue(app.staticTexts["SBU · RUMORE · PREFERITI"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.descendants(matching: .any)["Rumore rosa, 1 di 1"].exists)
        app.buttons["Togli dai preferiti"].tap()
        XCTAssertTrue(app.staticTexts["Tocca il cuore sotto un suono o un mix per ritrovarlo qui."].waitForExistence(timeout: 2))
        sleep(1)
        try app.auditAccessibility()
    }

    /// The player at the largest text size: the figure keeps one line, the controls stay reachable.
    @MainActor
    func testLargestTextAudit() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(it)", "-AppleLocale", "it_IT", "-lastSoundID", "noise.white", "-lastCategory", "sounds"]
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchEnvironment["SBU_NOISE_FILE"] = "ui-\(UUID().uuidString).json"
        app.launch()

        XCTAssertTrue(figure(app, "Rumore bianco").waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Riproduci"].isHittable)
        try app.auditAccessibility()
    }

    /// The figure: one element, the name then its place in the list.
    @MainActor
    private func figure(_ app: XCUIApplication, _ name: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", name + ",")).firstMatch
    }
}
