import XCTest

/// Drives the demo video (SBU-131) at a person's pace on the demo camera and codes that
/// `-FASTLANE_SNAPSHOT` opens: the camera, a link read and checked before it opens, the history,
/// then a code made in the creator.
/// Not a check: it runs only in the Snapshots scheme, while `simctl io recordVideo` records.
final class VideoTests: XCTestCase {
    @MainActor
    func testVideo() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        let sample = app.buttons["Leggi il codice di esempio"]
        XCTAssertTrue(sample.waitForExistence(timeout: 10))
        sleep(2)
        sample.tap()
        XCTAssertTrue(app.buttons["Apri il link"].waitForExistence(timeout: 5))
        sleep(3)
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["Cronologia"].tap()
        sleep(2)
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.buttons["Crea"].tap()
        app.buttons["Nuovo codice"].tap()
        app.buttons["Link"].tap()
        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText("sbu.dev")
        // The recorder runs behind the test: the last seconds hold the code on screen.
        sleep(5)
    }
}
