import XCTest

/// Drives the demo video (SBU-131): a new game, pieces dragged onto the board as a player would.
/// Not a check: it runs only in the Snapshots scheme, while `simctl io recordVideo` records.
final class VideoTests: XCTestCase {
    @MainActor
    func testVideo() {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(it)", "-AppleLocale", "it_IT", "-resetForUITests"]
        app.launch()
        let board = app.otherElements["Griglia"]
        XCTAssertTrue(board.waitForExistence(timeout: 10))
        sleep(2)
        // Finger targets on the board, as fractions of its side; the piece floats above the finger.
        let targets: [CGVector] = [
            CGVector(dx: 0.2, dy: 0.45), CGVector(dx: 0.55, dy: 0.45), CGVector(dx: 0.85, dy: 0.45),
            CGVector(dx: 0.2, dy: 0.8), CGVector(dx: 0.55, dy: 0.8), CGVector(dx: 0.85, dy: 0.8),
            CGVector(dx: 0.2, dy: 1.05), CGVector(dx: 0.55, dy: 1.05), CGVector(dx: 0.85, dy: 1.05),
        ]
        for (index, target) in targets.enumerated() {
            let pieces = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pezzo da'"))
            guard pieces.count > 0 else { break }
            pieces.element(boundBy: index % pieces.count).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.1, thenDragTo: board.coordinate(withNormalizedOffset: target), withVelocity: .slow, thenHoldForDuration: 0.2)
        }
        // The recorder runs behind the test: the last seconds hold the board on screen.
        sleep(4)
    }
}
