import XCTest

/// Drives the demo video (SBU-131) at a person's pace on the demo data: the monthly total and the
/// list, the free trial with its reminder, then the payments calendar.
/// Not a check: it runs only in the Snapshots scheme, while `simctl io recordVideo` records.
final class VideoTests: XCTestCase {
    @MainActor
    func testVideo() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["Musica"].firstMatch.waitForExistence(timeout: 10))
        sleep(2)
        app.swipeUp()
        sleep(1)
        app.swipeDown()
        sleep(1)

        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Corso di lingue'")).firstMatch.tap()
        XCTAssertTrue(app.buttons["edit"].waitForExistence(timeout: 5))
        sleep(1)
        app.swipeUp()
        sleep(2)
        // A detail is a sheet: dragged down from its top edge.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08))
            .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.98)))
        XCTAssertTrue(app.buttons["edit"].waitForNonExistence(timeout: 5))

        app.tabBars.buttons.element(boundBy: 1).tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Oggi'")).firstMatch.waitForExistence(timeout: 5))
        sleep(1)
        app.buttons.matching(NSPredicate(format: "label CONTAINS ': ' AND NOT (label BEGINSWITH 'Oggi')")).firstMatch.tap()
        // The recorder runs behind the test: the last seconds hold the calendar on screen.
        sleep(4)
    }
}
