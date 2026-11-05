import XCTest

/// Drives the App Store screenshots for `fastlane snapshot`.
/// First Home, the tab the app opens on, then the privacy promise in the Impostazioni tab.
final class SnapshotTests: XCTestCase {
    @MainActor
    func testScreenshots() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        snapshot("01-main")

        // Impostazioni is always the last tab; on a wide screen the tabs sit in a side toolbar.
        let tabs = app.tabBars.buttons.count > 0 ? app.tabBars.buttons : app.toolbars.buttons
        tabs.element(boundBy: tabs.count - 1).tap()
        snapshot("02-privacy")
    }
}
