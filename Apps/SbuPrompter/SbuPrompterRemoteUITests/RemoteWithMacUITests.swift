import XCTest

/// Drives the remote against a real Mac running Sbu Prompter on the same network.
/// Run it with the code shown in the Mac's menu:
/// `TEST_RUNNER_SBU_PROMPTER_CODE=1234 xcodebuild test -scheme SbuPrompterRemote ...`
/// Without the code (CI, no Mac nearby) it is skipped.
final class RemoteWithMacUITests: XCTestCase {
    @MainActor
    func testPairAndDriveTheMac() throws {
        guard let code = ProcessInfo.processInfo.environment["SBU_PROMPTER_CODE"] else {
            throw XCTSkip("No Mac code given.")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(it)", "-AppleLocale", "it_IT"]
        app.launch()

        let field = app.textFields["pairingCode"]
        let pad = app.descendants(matching: .any)["gesturePad"].firstMatch
        let connect = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Collega '")).firstMatch
        _ = field.waitForExistence(timeout: 20) || pad.exists
        if !field.exists, !pad.exists, connect.exists {
            connect.tap()
        }
        if field.waitForExistence(timeout: 20) {
            snapshot(app, "1-codice")
            field.typeText(code)
        }
        XCTAssertTrue(pad.waitForExistence(timeout: 15), "The Mac did not pair")
        snapshot(app, "2-collegato")

        let play = app.buttons["playPause"]
        play.tap()
        XCTAssertTrue(app.buttons["Pausa"].waitForExistence(timeout: 5), "The Mac did not start")
        sleep(4)
        snapshot(app, "3-in-lettura")

        let speed = app.staticTexts["speed"]
        let before = speed.label
        pad.swipeUp()
        XCTAssertTrue(waitForChange(speed, from: before), "The speed did not change")
        snapshot(app, "4-piu-veloce")

        pad.swipeLeft()
        sleep(2)
        snapshot(app, "5-sezione-successiva")

        app.buttons["cues"].tap()
        let firstCue = app.cells.buttons.firstMatch
        XCTAssertTrue(firstCue.waitForExistence(timeout: 5))
        snapshot(app, "6-sezioni")
        firstCue.tap()
        sleep(1)

        pad.tap()
        XCTAssertTrue(app.buttons["Avvia"].waitForExistence(timeout: 5), "The Mac did not pause")
        snapshot(app, "7-in-pausa")

        try app.performAccessibilityAudit(for: [.dynamicType, .elementDetection, .hitRegion, .sufficientElementDescription])
    }

    @MainActor
    private func waitForChange(_ element: XCUIElement, from label: String) -> Bool {
        let changed = expectation(for: NSPredicate(format: "label != %@", label), evaluatedWith: element)
        return XCTWaiter.wait(for: [changed], timeout: 5) == .completed
    }

    @MainActor
    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
