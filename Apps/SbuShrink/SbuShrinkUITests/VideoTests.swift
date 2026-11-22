import XCTest

/// Drives the demo video (SBU-131) at a person's pace on the demo that `-FASTLANE_SNAPSHOT`
/// opens with three picked videos: the settings with the estimate, the run, then the result
/// with the space saved.
/// Not a check: it runs only in the Snapshots scheme, while `simctl io recordVideo` records.
final class VideoTests: XCTestCase {
    @MainActor
    func testVideo() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["-DemoVideos", "3", "-DemoSpeed", "slow"]
        app.launch()

        let estimate = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'Dimensione stimata'")).firstMatch
        XCTAssertTrue(estimate.waitForExistence(timeout: 10))
        sleep(3)
        app.buttons["Comprimi"].tap()

        let keep = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Tieni'")).firstMatch
        XCTAssertTrue(keep.waitForExistence(timeout: 40))
        // The recorder runs behind the test: the last seconds hold the result on screen.
        sleep(5)
    }
}
