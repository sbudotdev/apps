import XCTest

/// Drives the App Store screenshots for `fastlane snapshot`. The slides are written before release.
final class SnapshotTests: XCTestCase {
    @MainActor
    func testScreenshots() {
        let app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-withVehicle"]
        setupSnapshot(app)
        app.launch()
        snapshot("01-main")
    }
}
