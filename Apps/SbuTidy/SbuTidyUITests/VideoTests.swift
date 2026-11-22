import XCTest

/// Drives the demo video (SBU-131) at a person's pace on the made-up home (`-FASTLANE_SNAPSHOT`):
/// today's chores, two ticked off as the figure drops, then the rooms, a room and a chore with its history.
/// Not a check: it runs only in the Snapshots scheme, while `simctl io recordVideo` records.
final class VideoTests: TidyUITestCase {
    @MainActor
    func testVideo() {
        let app = launch(["-FASTLANE_SNAPSHOT", "YES"])
        XCTAssertTrue(figureElement(app, "todayFigure").waitForExistence(timeout: 10))
        sleep(2)
        for _ in 0..<2 {
            app.switches.matching(NSPredicate(format: "identifier == 'todayChore' AND value == '0'")).firstMatch.tap()
            sleep(2)
        }

        app.buttons["rooms"].tap()
        let room = app.buttons.matching(identifier: "room").element(boundBy: 1)
        XCTAssertTrue(room.waitForExistence(timeout: 5))
        sleep(1)
        room.tap()
        let chore = app.buttons.matching(identifier: "chore").firstMatch
        XCTAssertTrue(chore.waitForExistence(timeout: 5))
        sleep(1)
        chore.tap()
        XCTAssertTrue(app.buttons["doneNow"].waitForExistence(timeout: 5))
        // The recorder runs behind the test: the last seconds hold the chore on screen.
        sleep(4)
    }
}
