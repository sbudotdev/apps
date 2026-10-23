import XCTest

/// Drives the App Store screenshots for `fastlane snapshot`, on the demo library that
/// `-FASTLANE_SNAPSHOT` opens: the space you can free, the lists beyond duplicates (blurry and
/// chat photos, similar videos, duplicate contacts), a card to swipe with a long video already in
/// the bin, the duplicates with the best shot, and the bin's final review.
final class SnapshotTests: XCTestCase {
    @MainActor
    private func back(_ app: XCUIApplication) {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    /// The home settles once the demo groups are found: the first row counts them.
    @MainActor
    private func waitForHome(_ app: XCUIApplication) {
        let found = NSPredicate(format: "label CONTAINS '4 gruppi' OR label CONTAINS '4 groups'")
        _ = app.buttons.matching(found).firstMatch.waitForExistence(timeout: 30)
        sleep(1)
    }

    @MainActor
    func testScreenshots() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        waitForHome(app)
        snapshot("01-main")

        // Down the home until the contacts row shows, under blurry and chat photos.
        let contacts = app.descendants(matching: .any)["home.contacts"].firstMatch
        for _ in 0..<4 where !contacts.isHittable {
            app.swipeUp(velocity: .slow)
            sleep(1)
        }
        snapshot("02-more")

        // Scorri le foto, then Recenti: the long concert video goes to the bin first, so the
        // figure counts something and the card is a photo.
        app.terminate()
        app.launch()
        waitForHome(app)
        app.descendants(matching: .any)["pill.months"].firstMatch.tap()
        app.descendants(matching: .any)["months.recent"].firstMatch.tap()
        let card = app.descendants(matching: .any).matching(identifier: "swipe.card").firstMatch
        _ = card.waitForExistence(timeout: 5)
        card.swipeLeft()
        sleep(2)
        snapshot("03-swipe")
        // Back from the deck lands on a home still settling: start it again instead.
        app.terminate()
        app.launch()
        waitForHome(app)

        app.descendants(matching: .any)["home.duplicates"].firstMatch.tap()
        app.descendants(matching: .any)["card.duplicate"].firstMatch.tap()
        sleep(1)
        snapshot("04-duplicates")

        app.descendants(matching: .any)["bottomAction"].firstMatch.tap()
        sleep(1)
        snapshot("05-bin")
    }
}
