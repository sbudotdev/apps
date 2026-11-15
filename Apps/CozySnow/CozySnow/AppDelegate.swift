import AppKit
import SwiftUI

/// Crea una finestra di neve per ogni schermo e gestisce il menu ❄︎ nella barra dei menu.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    private var overlays: [SnowOverlayWindow] = []
    private var statusItem: NSStatusItem?
    private var windowTimer: Timer?
    private var powerSource: CFRunLoopSource?

    // Salvato in UserDefaults, così l'app se lo ricorda al prossimo avvio.
    // (Le altre impostazioni sono in Settings.swift.)
    private var isSnowing: Bool {
        get { UserDefaults.standard.object(forKey: "isSnowing") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "isSnowing") }
    }

    private lazy var toggleItem = NSMenuItem(title: "Fai nevicare", action: nil, keyEquivalent: "s")
    private var densityItems: [NSMenuItem] = []

    /// La finestra Impostazioni: creata la prima volta che serve, poi riusata.
    private lazy var settingsWindow: NSWindow = {
        let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
        window.title = "Impostazioni CozySnow"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.delegate = self   // per sapere quando viene chiusa
        window.center()
        return window
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Per la neve sul Dock serve il permesso Accessibilità: se manca, macOS mostra la richiesta.
        if Settings.shared.values.groundSnow {
            AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        }
        setupStatusItem()
        setupMainMenu()
        rebuildOverlays()

        // A batteria la neve va a 30 fotogrammi al secondo.
        powerSource = observePowerSource()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(powerSourceDidChange),
            name: .powerSourceDidChange,
            object: nil
        )

        // Se colleghi/scolleghi un monitor o cambi risoluzione, ricreiamo le finestre.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // Aperta a mano (doppio clic, `open`)? Mostriamo subito le Impostazioni.
        // All'avvio automatico al login no: lì vogliamo solo la neve.
        if !launchedAsLoginItem() { openSettings() }

        // Controlliamo spesso dove sono le finestre (per l'accumulo).
        windowTimer = Timer.scheduledTimer(withTimeInterval: Tuning.windowRefreshInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshWindows() }
        }
    }

    // MARK: - Finestre

    @objc private func screensDidChange() {
        rebuildOverlays()
    }

    @objc private func powerSourceDidChange() {
        let onBattery = isOnBattery()
        overlays.forEach { $0.setOnBattery(onBattery) }
    }

    private func rebuildOverlays() {
        overlays.forEach { $0.close() }
        overlays = NSScreen.screens.map { SnowOverlayWindow(screen: $0) }
        powerSourceDidChange()
        overlays.forEach { $0.setSnowing(isSnowing) }
        refreshWindows()
    }

    private func refreshWindows() {
        guard isSnowing else { return }
        // Una sola lettura, condivisa da tutti gli schermi.
        let edges = currentWindowEdges()
        let dock = currentDockFrame()
        overlays.forEach { $0.updateWindows(edges, dock: dock) }
    }

    // MARK: - Menu

    /// Il menu in alto (quello col nome dell'app), visibile mentre le Impostazioni sono aperte.
    private func setupMainMenu() {
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "Chiudi finestra", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Esci da CozySnow", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        let appItem = NSMenuItem()
        appItem.submenu = appMenu
        let mainMenu = NSMenu()
        mainMenu.addItem(appItem)
        NSApp.mainMenu = mainMenu
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "snowflake", accessibilityDescription: "CozySnow")
        item.button?.toolTip = "CozySnow"

        let menu = NSMenu()
        menu.delegate = self   // per aggiornare le spunte ogni volta che si apre

        toggleItem.target = self
        toggleItem.action = #selector(toggleSnow)
        menu.addItem(toggleItem)

        let meltItem = NSMenuItem(title: "Sciogli la neve", action: #selector(meltSnow), keyEquivalent: "r")
        meltItem.target = self
        menu.addItem(meltItem)

        menu.addItem(.separator())

        let densityHeader = NSMenuItem(title: "Intensità", action: nil, keyEquivalent: "")
        densityHeader.isEnabled = false
        menu.addItem(densityHeader)

        densityItems = Density.allCases.map { d in
            // ⌘1, ⌘2, ⌘3 nell'ordine del menu, mentre il menu è aperto.
            let mi = NSMenuItem(title: d.title, action: #selector(selectDensity(_:)), keyEquivalent: "\(d.rawValue + 1)")
            mi.target = self
            mi.tag = d.rawValue
            mi.indentationLevel = 1
            menu.addItem(mi)
            return mi
        }

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Impostazioni…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem(title: "Esci da CozySnow", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        item.menu = menu
        statusItem = item
        updateMenuState()
    }

    private func updateMenuState() {
        toggleItem.state = isSnowing ? .on : .off
        // Spunta sull'intensità solo se lo slider "Quantità" è esattamente su quel valore.
        let count = Settings.shared.values.flakeCount
        for mi in densityItems {
            mi.state = Density(rawValue: mi.tag)?.flakesPerReferenceScreen == count ? .on : .off
        }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        updateMenuState()
    }

    @objc private func toggleSnow() {
        isSnowing.toggle()
        overlays.forEach { $0.setSnowing(isSnowing) }
        updateMenuState()
    }

    @objc private func meltSnow() {
        overlays.forEach { $0.meltAll() }
    }

    @objc private func selectDensity(_ sender: NSMenuItem) {
        guard let density = Density(rawValue: sender.tag) else { return }
        Settings.shared.values.flakeCount = density.flakesPerReferenceScreen
    }

    /// Riaprire l'app mentre è già in esecuzione (doppio clic, `open CozySnow.app`) apre le Impostazioni.
    /// Utile perché l'icona ❄︎ può finire nascosta dietro il notch se la barra dei menu è piena.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings()
        return true
    }

    @objc private func openSettings() {
        // App senza Dock: va "attivata" esplicitamente, altrimenti la finestra resta dietro alle altre.
        // Mentre le Impostazioni sono aperte, l'app si comporta come una normale:
        // icona nel Dock, ⌘Tab, menu in alto. Alla chiusura torna invisibile (vedi windowWillClose).
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        settingsWindow.makeKeyAndOrderFront(nil)
        settingsWindow.orderFrontRegardless()   // davanti anche se macOS non ci ha ancora "attivati"
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)   // via dal Dock: resta solo la neve
    }

    /// macOS segnala nell'evento di avvio se l'app è partita come elemento di login.
    private func launchedAsLoginItem() -> Bool {
        let event = NSAppleEventManager.shared().currentAppleEvent
        return event?.eventID == kAEOpenApplication
            && event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }
}
