import AppKit
import SwiftUI

/// Crea una finestra di neve per ogni schermo e gestisce il menu ❄︎ nella barra dei menu.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var overlays: [SnowOverlayWindow] = []
    private var statusItem: NSStatusItem?
    private var windowTimer: Timer?

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
        window.center()
        return window
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Per la neve sul Dock serve il permesso Accessibilità: se manca, macOS mostra la richiesta.
        if Settings.shared.values.groundSnow {
            AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        }
        setupStatusItem()
        rebuildOverlays()

        // Se colleghi/scolleghi un monitor o cambi risoluzione, ricreiamo le finestre.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // 8 volte al secondo controlliamo dove sono le finestre (per l'accumulo).
        windowTimer = Timer.scheduledTimer(withTimeInterval: 0.125, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refreshWindows() }
        }
    }

    // MARK: - Finestre

    @objc private func screensDidChange() {
        rebuildOverlays()
    }

    private func rebuildOverlays() {
        overlays.forEach { $0.close() }
        overlays = NSScreen.screens.map { SnowOverlayWindow(screen: $0) }
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

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "snowflake", accessibilityDescription: "CozySnow")

        let menu = NSMenu()
        menu.delegate = self   // per aggiornare le spunte ogni volta che si apre

        toggleItem.target = self
        toggleItem.action = #selector(toggleSnow)
        menu.addItem(toggleItem)

        let meltItem = NSMenuItem(title: "Sciogli la neve", action: #selector(meltSnow), keyEquivalent: "r")
        meltItem.target = self
        menu.addItem(meltItem)

        menu.addItem(.separator())

        let densityHeader = NSMenuItem(title: "Intensità (scorciatoie)", action: nil, keyEquivalent: "")
        densityHeader.isEnabled = false
        menu.addItem(densityHeader)

        densityItems = Density.allCases.map { d in
            let mi = NSMenuItem(title: d.title, action: #selector(selectDensity(_:)), keyEquivalent: "")
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

        menu.addItem(NSMenuItem(title: "Esci", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

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
        NSApp.activate()
        settingsWindow.makeKeyAndOrderFront(nil)
    }
}
