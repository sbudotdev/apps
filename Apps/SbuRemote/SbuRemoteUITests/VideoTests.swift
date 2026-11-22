import XCTest

/// Drives the demo video (SBU-131) at a person's pace on the demo TV (`-demoTV`, debug builds
/// only, no network): the arrows and OK, the volume, the TV's apps, then a search typed on the keyboard.
/// Not a check: it runs only in the Snapshots scheme, while `simctl io recordVideo` records.
final class VideoTests: XCTestCase {
    @MainActor
    func testVideo() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["-demoTV", "-navigationMode", "dPad"]
        app.launch()

        let ok = app.buttons["OK"]
        XCTAssertTrue(ok.waitForExistence(timeout: 10))
        sleep(1)
        for key in ["Destra", "Destra", "Giù", "OK"] {
            app.buttons[key].tap()
            usleep(600_000)
        }
        app.buttons["Alza il volume"].press(forDuration: 1)
        sleep(1)

        app.buttons["App"].tap()
        XCTAssertTrue(app.buttons["YouTube"].waitForExistence(timeout: 5))
        sleep(2)
        app.buttons["Fine"].tap()

        app.buttons["Tastiera"].tap()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("Concerto")
        sleep(2)
        app.buttons["Fine"].tap()
        sleep(1)
    }
}
