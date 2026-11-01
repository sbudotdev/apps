import XCTest

/// Drives the whole flow on the simulator: first run, tour, place, route preview, guidance, settings.
final class ZTLFlowTests: XCTestCase {
    private let folder = ProcessInfo.processInfo.environment["ZTL_SHOTS"]

    @MainActor
    private func shot(_ app: XCUIApplication, _ name: String) {
        guard let folder else { return }
        try? app.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: folder).appendingPathComponent(name + ".png"))
    }

    @MainActor
    func testFirstRunAddsAVehicleAndEndsTheTour() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-AppleLanguages", "(it)", "-AppleLocale", "it_IT"]
        app.launch()
        shot(app, "01-first-run")
        app.buttons["addVehicle"].tap()
        let name = app.textFields.firstMatch
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.typeText("Panda")
        shot(app, "02-name")
        app.buttons["continue"].tap()
        shot(app, "03-kind")
        app.buttons["continue"].tap()
        shot(app, "04-fuel")
        app.buttons["continue"].tap()
        app.buttons["Euro 5"].tap()
        shot(app, "05-euro")
        app.buttons["continue"].tap()
        shot(app, "06-review")
        app.buttons["continue"].tap()
        let next = app.buttons["tourNext"]
        XCTAssertTrue(next.waitForExistence(timeout: 8))
        sleep(1)
        shot(app, "07-tour-1")
        next.tap()
        sleep(1)
        shot(app, "08-tour-2")
        next.tap()
        sleep(1)
        shot(app, "09-tour-3")
        next.tap()
        sleep(1)
        XCTAssertFalse(next.exists)
        shot(app, "10-home")
    }

    @MainActor
    func testSearchPlaceRouteAndGuide() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-withVehicle", "-AppleLanguages", "(it)", "-AppleLocale", "it_IT"]
        app.launch()
        app.buttons["Cerca un luogo"].tap()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("Duomo Milano")
        let result = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'Duomo'")).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 20))
        shot(app, "11-search")
        result.tap()
        let go = app.buttons["go"]
        XCTAssertTrue(go.waitForExistence(timeout: 5))
        sleep(2)
        shot(app, "12-place")
        go.tap()
        let start = app.buttons["start"]
        XCTAssertTrue(start.waitForExistence(timeout: 30))
        sleep(2)
        shot(app, "13-preview")
        start.tap()
        sleep(3)
        shot(app, "14-guidance")
    }

    @MainActor
    func testSettingsAndZoneList() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-withVehicle", "-AppleLanguages", "(it)", "-AppleLocale", "it_IT"]
        app.launch()
        app.buttons["Impostazioni"].tap()
        sleep(1)
        shot(app, "16-settings")
        app.swipeUp()
        sleep(1)
        shot(app, "17-settings-more")
        app.terminate()
        app.launch()
        app.buttons["ZTL"].tap()
        sleep(1)
        shot(app, "15-zones")
    }

    @MainActor
    func testAccessibilityAudit() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-withVehicle", "-AppleLanguages", "(it)", "-AppleLocale", "it_IT"]
        app.launch()
        try app.performAccessibilityAudit(for: [.sufficientElementDescription, .hitRegion, .dynamicType]) { issue in
            print("AUDIT", issue.compactDescription, issue.element?.description ?? "-")
            // Apple's own Maps logo and legal link inside the map aren't ours to size.
            return issue.element?.label.contains("legali") == true || issue.element?.label.contains("Mappe") == true
        }
    }
}
