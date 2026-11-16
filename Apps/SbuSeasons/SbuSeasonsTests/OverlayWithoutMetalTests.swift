import AppKit
import Metal
import Testing
@testable import SbuSeasons

/// Senza GPU (`MTLCreateSystemDefaultDevice()` può dare nil, per esempio su un Mac senza
/// schermo attivo) la finestra della neve non si crea, invece di far chiudere l'app (MGS-686).
@MainActor
@Test func overlayIsSkippedWithoutAMetalDevice() throws {
    let screen = try #require(NSScreen.screens.first)
    #expect(OverlayWindow(screen: screen, device: nil) == nil)
}
