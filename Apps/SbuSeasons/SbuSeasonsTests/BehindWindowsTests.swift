import AppKit
import Testing
@testable import SbuSeasons

/// "Dietro le finestre": gli effetti sopra la scrivania ma sotto le finestre delle app.
struct BehindWindowsTests {
    @Test func itIsOffByDefaultAndOlderSavesKeepItOff() throws {
        #expect(!SnowSettings().behindWindows)
        let older = try JSONSerialization.data(withJSONObject: ["flakeCount": 300.0])
        #expect(!SnowSettings(saved: older).behindWindows)
    }

    @Test func onTopTheEffectsStayAboveWindowsAndTheDock() {
        #expect(OverlayWindow.level(behindWindows: false) == .statusBar)
    }

    @Test func behindTheEffectsSitOnTheDesktopUnderEveryAppWindow() {
        let level = OverlayWindow.level(behindWindows: true)
        #expect(level < .normal)
        #expect(level.rawValue > Int(CGWindowLevelForKey(.desktopWindow)))
    }
}
