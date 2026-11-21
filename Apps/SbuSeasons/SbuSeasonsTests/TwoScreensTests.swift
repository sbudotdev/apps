import AppKit
import Testing
@testable import SbuSeasons

/// Con due schermi a frequenze diverse (144 e 60 Hz) la neve va alla stessa velocità su tutti e due (SBU-19).
/// Con la sola `SKView` SpriteKit chiamava `update` solo sulla scena dello schermo a 60 Hz: sull'altro la neve si fermava.
/// Lo schermo in più è virtuale, con una frequenza diversa da quella dello schermo principale.
@MainActor
@Test(.timeLimit(.minutes(1)))
func snowKeepsTimeOnTwoScreensWithDifferentRefreshRates() throws {
    // Senza sessione grafica completa (agenti, CI) lo schermo virtuale non si crea: il test si salta, non fallisce.
    guard let main = NSScreen.screens.first,
          let display = VirtualDisplay(refreshRate: main.maximumFramesPerSecond == 60 ? 144 : 60) else {
        try Test.cancel("Schermo virtuale non disponibile: serve una sessione grafica completa")
    }
    defer { withExtendedLifetime(display) {} }
    let deadline = Date.now.addingTimeInterval(5)
    while NSScreen.screens.count < 2 && Date.now < deadline { RunLoop.main.run(until: .now.addingTimeInterval(0.05)) }
    try #require(NSScreen.screens.count >= 2)

    let overlays = NSScreen.screens.map { OverlayWindow(screen: $0) }
    defer { overlays.forEach { $0.close() } }
    overlays.forEach { $0.setEnergy(onBattery: false, reduceMotion: false); $0.setSnowing(true) }
    RunLoop.main.run(until: .now.addingTimeInterval(0.5))

    let start = overlays.map(\.elapsed)
    let began = Date.now
    RunLoop.main.run(until: .now.addingTimeInterval(2))
    let wall = Date.now.timeIntervalSince(began)
    for (overlay, before) in zip(overlays, start) {
        // La neve si muove col tempo simulato: deve stare al passo con l'orologio su ogni schermo.
        #expect(Double(overlay.elapsed - before) > wall * 0.8, "schermo \(overlay.frame.origin): \(overlay.elapsed - before) s simulati in \(wall) s")
    }
}

/// Uno schermo virtuale (`CGVirtualDisplay`, API privata di CoreGraphics), solo per i test: resta finché vive l'oggetto.
@MainActor
private final class VirtualDisplay {
    private let display: AnyObject

    init?(refreshRate: Double, width: UInt32 = 1920, height: UInt32 = 1080) {
        guard let descriptorClass = NSClassFromString("CGVirtualDisplayDescriptor") as? NSObject.Type,
              let modeClass = NSClassFromString("CGVirtualDisplayMode") as? NSObject.Type,
              let settingsClass = NSClassFromString("CGVirtualDisplaySettings") as? NSObject.Type,
              let displayClass = NSClassFromString("CGVirtualDisplay") as? NSObject.Type else { return nil }

        let descriptor = descriptorClass.init()
        descriptor.setValue(DispatchQueue.main, forKey: "queue")
        descriptor.setValue("Sbu Seasons test", forKey: "name")
        descriptor.setValue(width, forKey: "maxPixelsWide")
        descriptor.setValue(height, forKey: "maxPixelsHigh")
        descriptor.setValue(NSValue(size: NSSize(width: 600, height: 340)), forKey: "sizeInMillimeters")
        descriptor.setValue(0x5B19, forKey: "serialNum")
        descriptor.setValue(0x1234, forKey: "productID")
        descriptor.setValue(0x3456, forKey: "vendorID")

        typealias ModeInit = @convention(c) (AnyObject, Selector, UInt32, UInt32, Double) -> Unmanaged<AnyObject>?
        let modeInit = NSSelectorFromString("initWithWidth:height:refreshRate:")
        guard let modeAlloc = modeClass.perform(NSSelectorFromString("alloc"))?.takeUnretainedValue(),
              let mode = unsafeBitCast(class_getMethodImplementation(modeClass, modeInit), to: ModeInit.self)(
                modeAlloc, modeInit, width, height, refreshRate)?.takeRetainedValue() else { return nil }

        typealias DisplayInit = @convention(c) (AnyObject, Selector, AnyObject) -> Unmanaged<AnyObject>?
        let displayInit = NSSelectorFromString("initWithDescriptor:")
        guard let displayAlloc = displayClass.perform(NSSelectorFromString("alloc"))?.takeUnretainedValue(),
              let display = unsafeBitCast(class_getMethodImplementation(displayClass, displayInit), to: DisplayInit.self)(
                displayAlloc, displayInit, descriptor)?.takeRetainedValue() else { return nil }

        let settings = settingsClass.init()
        settings.setValue([mode], forKey: "modes")
        settings.setValue(0, forKey: "hiDPI")
        typealias Apply = @convention(c) (AnyObject, Selector, AnyObject) -> Bool
        let apply = NSSelectorFromString("applySettings:")
        guard unsafeBitCast(class_getMethodImplementation(displayClass, apply), to: Apply.self)(display, apply, settings) else { return nil }
        self.display = display
    }
}

/// La scelta degli schermi (SBU-227): di base tutti accesi, l'ultimo acceso non si spegne, la scelta resta tra un avvio e l'altro.
struct ScreenChoiceTests {
    private let screens = ["UUID-A", "UUID-B", "UUID-C"]

    @Test func theChoiceIsSavedAndReadBack() throws {
        var settings = SnowSettings()
        settings.setEffect(false, onScreen: "UUID-B")
        let again = SnowSettings(saved: try JSONEncoder().encode(settings))
        #expect(!again.showsEffect(onScreen: "UUID-B", connected: screens))
        #expect(again.showsEffect(onScreen: "UUID-A", connected: screens))
    }

    @Test func aNewScreenStartsOn() {
        var settings = SnowSettings()
        settings.setEffect(false, onScreen: "UUID-B")
        #expect(settings.showsEffect(onScreen: "UUID-NEW", connected: screens + ["UUID-NEW"]))
    }

    @Test func aReconnectedScreenFindsItsChoice() {
        var settings = SnowSettings()
        settings.setEffect(false, onScreen: "UUID-B")
        #expect(settings.showsEffect(onScreen: "UUID-A", connected: ["UUID-A"]))     // B scollegato
        #expect(!settings.showsEffect(onScreen: "UUID-B", connected: screens))       // B ricollegato: torna spento
    }

    @Test func theLastScreenOnCannotBeTurnedOff() {
        var settings = SnowSettings()
        #expect(settings.canTurnOffEffect(onScreen: "UUID-A", connected: screens))
        settings.setEffect(false, onScreen: "UUID-A")
        settings.setEffect(false, onScreen: "UUID-B")
        #expect(!settings.canTurnOffEffect(onScreen: "UUID-C", connected: screens), "l'ultimo acceso")
        #expect(settings.canTurnOffEffect(onScreen: "UUID-A", connected: screens), "già spento: si può solo riaccendere")
    }

    @Test func ifEveryConnectedScreenIsOffTheEffectShowsOnAll() {
        // A e B spenti, C acceso; C si scollega: restano due schermi spenti, l'effetto si vede su tutti e due.
        var settings = SnowSettings()
        settings.setEffect(false, onScreen: "UUID-A")
        settings.setEffect(false, onScreen: "UUID-B")
        #expect(settings.showsEffect(onScreen: "UUID-A", connected: ["UUID-A", "UUID-B"]))
        #expect(settings.showsEffect(onScreen: "UUID-B", connected: ["UUID-A", "UUID-B"]))
        #expect(!settings.showsEffect(onScreen: "UUID-A", connected: screens), "con C ricollegato tornano spenti")
    }
}
