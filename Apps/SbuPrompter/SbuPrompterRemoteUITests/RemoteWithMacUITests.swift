import XCTest

/// Drives the remote against a real Mac running Sbu Prompter on the same network.
/// Run it with the code shown in the Mac's menu:
/// `TEST_RUNNER_SBU_PROMPTER_CODE=1234 xcodebuild test -scheme SbuPrompterRemote ...`
/// Without the code (CI, no Mac nearby) it is skipped. `TEST_RUNNER_SBU_PROMPTER_SHOTS=<folder>` also saves the screenshots there,
/// `TEST_RUNNER_SBU_PROMPTER_LANG=en` runs it in English (for the en-US store screenshots).
final class RemoteWithMacUITests: XCTestCase {
    @MainActor
    func testPairAndDriveTheMac() throws {
        guard let code = ProcessInfo.processInfo.environment["SBU_PROMPTER_CODE"] else {
            throw XCTSkip("No Mac code given.")
        }
        continueAfterFailure = false
        let english = ProcessInfo.processInfo.environment["SBU_PROMPTER_LANG"] == "en"
        // The labels the test finds buttons by, in the language it runs in.
        func label(_ italian: String) -> String {
            guard english else { return italian }
            return ["Collega ": "Connect ", "Riavvolgi": "Rewind", "Più veloce": "Faster", "Pausa": "Pause", "Avvia": "Start"][italian]!
        }
        let app = XCUIApplication()
        app.launchArguments = english ? ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"] : ["-AppleLanguages", "(it)", "-AppleLocale", "it_IT"]
        app.launch()

        let field = app.textFields["pairingCode"]
        let pad = app.descendants(matching: .any)["gesturePad"].firstMatch
        let connect = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", label("Collega "))).firstMatch
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

        // Every control fits on the screen without scrolling (QA SBU-173: Riavvolgi and Sezioni were below the fold).
        let screen = app.windows.firstMatch.frame
        for button in [app.buttons[label("Riavvolgi")], app.buttons["cues"], app.buttons[label("Più veloce")]] {
            XCTAssertTrue(screen.contains(button.frame), "\(button.label) is below the fold")
        }

        // Start from the top: a previous run may have left the Mac at the end of the script.
        app.buttons[label("Riavvolgi")].tap()
        let play = app.buttons["playPause"]
        play.tap()
        XCTAssertTrue(app.buttons[label("Pausa")].waitForExistence(timeout: 5), "The Mac did not start")
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
        let firstCue = app.buttons.matching(identifier: "cue").firstMatch
        XCTAssertTrue(firstCue.waitForExistence(timeout: 10), "The cue list did not open")
        snapshot(app, "6-sezioni")
        firstCue.tap()
        sleep(1)

        // The short sample script may have reached its end and stopped: the tap must flip whatever it is.
        let after = app.buttons[label("Pausa")].exists ? label("Avvia") : label("Pausa")
        pad.tap()
        XCTAssertTrue(app.buttons[after].waitForExistence(timeout: 5), "The tap did not reach the Mac")
        snapshot(app, "7-tocco")

        try app.performAccessibilityAudit(for: [.dynamicType, .elementDetection, .hitRegion, .sufficientElementDescription]) { issue in
            // SbuKit's uppercase cartiglio (SbuScreenTitle) scales with .caption2, which the audit reads
            // as partial support; it is shared by every app, so it is not this app's to change.
            if issue.auditType == .dynamicType, let label = issue.element?.label, label == label.uppercased() {
                return true
            }
            XCTFail("\(issue.compactDescription): \(issue.element?.debugDescription ?? "no element")")
            return true
        }
    }

    @MainActor
    private func waitForChange(_ element: XCUIElement, from label: String) -> Bool {
        let changed = expectation(for: NSPredicate(format: "label != %@", label), evaluatedWith: element)
        return XCTWaiter.wait(for: [changed], timeout: 5) == .completed
    }

    @MainActor
    private func snapshot(_ app: XCUIApplication, _ name: String) {
        let screenshot = app.screenshot()
        // Also on disk when asked: xcodebuild can hang after the run and leave the result bundle unreadable.
        if let folder = ProcessInfo.processInfo.environment["SBU_PROMPTER_SHOTS"] {
            try? screenshot.pngRepresentation.write(to: URL(filePath: folder).appending(path: "\(name).png"))
        }
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
