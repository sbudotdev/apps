import XCTest

/// Drives the demo video (SBU-131) at a person's pace on the screenshot data: the moon today,
/// the next days with a swipe, back to today, then moonrise, moonset and the next phases in Rome.
/// Not a check: it runs only in the Snapshots scheme, while `simctl io recordVideo` records.
final class VideoTests: XCTestCase {
    @MainActor
    func testVideo() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        let figure = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS '%, '")).firstMatch
        XCTAssertTrue(figure.waitForExistence(timeout: 10))
        sleep(2)

        for _ in 0..<3 {
            figure.swipeLeft()
            sleep(1)
        }
        sleep(1)
        app.buttons["today"].tap()
        sleep(2)

        let lower = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75))
        lower.press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.283)))
        sleep(3)
        app.swipeDown()
        sleep(1)
    }
}
