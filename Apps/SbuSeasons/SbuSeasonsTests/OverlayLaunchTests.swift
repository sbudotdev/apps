import AppKit
import Testing
@testable import SbuSeasons

/// La sequenza di `rebuildOverlays()` all'avvio, anche a batteria (30 fps, come su un MacBook):
/// la finestra si crea, disegna qualche fotogramma e si chiude senza chiudere l'app (MGS-686).
@MainActor
@Test(arguments: [false, true])
func overlayStartsAndDrawsOnBatteryOrPower(onBattery: Bool) throws {
    let screen = try #require(NSScreen.screens.first)
    let overlay = try #require(OverlayWindow(screen: screen))
    overlay.setOnBattery(onBattery)
    overlay.setSnowing(true)
    RunLoop.main.run(until: .now.addingTimeInterval(0.5))
    overlay.close()
}
