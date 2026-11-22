import XCTest

/// Drives the demo video (SBU-131) at a person's pace: rain playing, the next sound, an alarm,
/// then the bedside clock. Runs on a throwaway file, so the alarm is its own.
/// Not a check: it runs only in the Snapshots scheme, while `simctl io recordVideo` records.
final class VideoTests: XCTestCase {
    @MainActor
    func testVideo() {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["-lastCategory", "sounds", "-lastSoundID", "rain.light"]
        app.launchEnvironment["SBU_NOISE_FILE"] = "video-\(UUID().uuidString).json"
        app.launchEnvironment["SBU_NOISE_BACKUP"] = "silent"
        app.launch()

        let play = app.buttons["Riproduci"]
        XCTAssertTrue(play.waitForExistence(timeout: 10))
        play.tap()
        sleep(2)
        app.buttons["Successivo"].tap()
        sleep(2)

        app.buttons["Timer"].tap()
        sleep(1)
        app.buttons["Aggiungi"].tap()
        app.buttons["Nuova sveglia"].tap()
        sleep(1)
        app.buttons["Salva"].tap()
        sleep(2)
        app.buttons["Fine"].tap()

        app.buttons["Dormi"].tap()
        sleep(3)
        app.buttons["Pausa"].firstMatch.tap()
    }
}
