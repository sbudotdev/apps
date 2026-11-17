import AppKit
import SwiftUI

/// Crea una finestra di neve per ogni schermo e gestisce il menu ❄︎ nella barra dei menu.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    private var overlays: [OverlayWindow] = []
    private var statusItem: NSStatusItem?
    private var windowTimer: Timer?
    private var powerSource: CFRunLoopSource?
    private var windowShakes = WindowShakes()

    // Salvato in UserDefaults, così l'app se lo ricorda al prossimo avvio.
    // (Le altre impostazioni sono in Settings.swift.)
    private var isSnowing: Bool {
        get { UserDefaults.standard.object(forKey: "isSnowing") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "isSnowing") }
    }

    private lazy var toggleItem = NSMenuItem(title: String(localized: "Fai nevicare"), action: nil, keyEquivalent: "s")
    private var densityItems: [NSMenuItem] = []
    /// L'intensità continua, sotto Leggera/Media/Forte: è lo stesso valore di "Quantità di fiocchi".
    private lazy var intensitySlider: NSSlider = {
        let slider = NSSlider(value: Settings.shared.values.flakeCount, minValue: Density.range.lowerBound,
                              maxValue: Density.range.upperBound, target: self, action: #selector(intensityChanged(_:)))
        slider.isContinuous = true
        slider.controlSize = .small
        slider.setAccessibilityLabel(String(localized: "Intensità"))
        return slider
    }()
    private var seasonItems: [NSMenuItem] = []

    /// La finestra Impostazioni: creata la prima volta che serve, poi riusata.
    private lazy var settingsWindow: NSWindow = {
        let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
        window.title = String(localized: "Impostazioni \(SbuSeasonsApp.name)")
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.delegate = self   // per sapere quando viene chiusa
        window.center()
        return window
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        PreviousDefaults.migrate()   // prima di leggere qualsiasi impostazione
        // Per la neve sul Dock serve il permesso Accessibilità: se manca, macOS mostra la richiesta.
        if Settings.shared.values.groundSnow {
            AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        }
        setupStatusItem()
        setupMainMenu()
        rebuildOverlays()
        // La stagione cambia dal menu ❄︎ o dalle Impostazioni: neve e icona seguono subito.
        Settings.shared.observeSeason { [weak self] in self?.seasonDidChange() }

        // A batteria la neve va a 30 fotogrammi al secondo.
        powerSource = observePowerSource()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(powerSourceDidChange),
            name: .powerSourceDidChange,
            object: nil
        )

        // "Riduci movimento" si può cambiare mentre l'app gira.
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(powerSourceDidChange),
            name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification,
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

    /// Batteria o "Riduci movimento" cambiati: fotogrammi e movimento si adeguano.
    @objc private func powerSourceDidChange() {
        let onBattery = isOnBattery()
        let reduceMotion = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        overlays.forEach { $0.setEnergy(onBattery: onBattery, reduceMotion: reduceMotion) }
    }

    private func rebuildOverlays() {
        overlays.forEach { $0.close() }
        overlays = NSScreen.screens.map { OverlayWindow(screen: $0) }
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
        let shaken = windowShakes.update(edges, at: ProcessInfo.processInfo.systemUptime)
        if !shaken.isEmpty { overlays.forEach { $0.windowsShaken(shaken) } }
    }

    // MARK: - Menu

    /// Il menu in alto (quello col nome dell'app), visibile mentre le Impostazioni sono aperte.
    private func setupMainMenu() {
        let appMenu = NSMenu()
        appMenu.addItem(aboutItem())
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: String(localized: "Chiudi finestra"), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: String(localized: "Esci da \(SbuSeasonsApp.name)"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        let appItem = NSMenuItem()
        appItem.submenu = appMenu
        let mainMenu = NSMenu()
        mainMenu.addItem(appItem)
        NSApp.mainMenu = mainMenu
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.toolTip = SbuSeasonsApp.name

        let menu = NSMenu()
        menu.delegate = self   // per aggiornare le spunte ogni volta che si apre

        toggleItem.target = self
        toggleItem.action = #selector(toggleSnow)
        menu.addItem(toggleItem)

        let meltItem = NSMenuItem(title: String(localized: "Sciogli la neve"), action: #selector(meltSnow), keyEquivalent: "r")
        meltItem.target = self
        menu.addItem(meltItem)

        let clearItem = NSMenuItem(title: String(localized: "Togli le palle di neve"), action: #selector(clearSnowballs), keyEquivalent: "")
        clearItem.target = self
        clearItem.toolTip = String(localized: "Per fare una palla di neve, tieni premuto ⌥ e passa il cursore sulla neve posata.")
        menu.addItem(clearItem)

        // La palla di vetro si scuote anche dal menu: non tutti possono scuotere il mouse.
        let globeItem = NSMenuItem(title: String(localized: "Scuoti la palla di vetro"), action: #selector(shakeGlobe), keyEquivalent: "")
        globeItem.target = self
        menu.addItem(globeItem)

        menu.addItem(.separator())

        // Stagione: un sottomenu con l'elenco di `Seasons.all`.
        let seasonMenu = NSMenu()
        seasonItems = Seasons.all.map { season in
            let mi = NSMenuItem(title: season.title, action: #selector(selectSeason(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = season.id
            mi.image = NSImage(systemSymbolName: season.symbol, accessibilityDescription: nil)
            seasonMenu.addItem(mi)
            return mi
        }
        let seasonItem = NSMenuItem(title: String(localized: "Stagione"), action: nil, keyEquivalent: "")
        seasonItem.submenu = seasonMenu
        menu.addItem(seasonItem)

        let densityHeader = NSMenuItem(title: String(localized: "Intensità"), action: nil, keyEquivalent: "")
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
        // Rientrato come le voci sopra; la larghezza la allarga il menu.
        let sliderRow = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        intensitySlider.frame = NSRect(x: 30, y: 2, width: 156, height: 20)
        intensitySlider.autoresizingMask = [.width]
        sliderRow.addSubview(intensitySlider)
        let sliderItem = NSMenuItem()
        sliderItem.view = sliderRow
        menu.addItem(sliderItem)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: String(localized: "Impostazioni…"), action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(aboutItem())
        menu.addItem(NSMenuItem(title: String(localized: "Esci da \(SbuSeasonsApp.name)"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        item.menu = menu
        statusItem = item
        updateMenuState()
    }

    private func updateMenuState() {
        toggleItem.state = isSnowing ? .on : .off
        let season = Settings.shared.season
        // L'icona nella barra dei menu segue la stagione.
        statusItem?.button?.image = NSImage(systemSymbolName: season.symbol, accessibilityDescription: SbuSeasonsApp.name)
        for mi in seasonItems { mi.state = mi.representedObject as? String == season.id ? .on : .off }
        // Spunta sull'intensità solo se lo slider "Quantità" è esattamente su quel valore.
        let count = Settings.shared.values.flakeCount
        for mi in densityItems {
            mi.state = Density(rawValue: mi.tag)?.flakesPerReferenceScreen == count ? .on : .off
        }
        intensitySlider.doubleValue = count
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

    @objc private func clearSnowballs() {
        overlays.forEach { $0.clearSnowballs() }
    }

    @objc private func shakeGlobe() {
        overlays.forEach { $0.shakeGlobe() }
    }

    @objc private func selectSeason(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        Settings.shared.seasonID = id   // il resto lo fa seasonDidChange
    }

    private func seasonDidChange() {
        let season = Settings.shared.season
        overlays.forEach { $0.setSeason(season) }
        updateMenuState()
    }

    @objc private func selectDensity(_ sender: NSMenuItem) {
        guard let density = Density(rawValue: sender.tag) else { return }
        Settings.shared.values.flakeCount = density.flakesPerReferenceScreen
    }

    /// Le particelle in più nascono in cima e quelle in meno spariscono: chi sta cadendo non salta.
    @objc private func intensityChanged(_ sender: NSSlider) {
        Settings.shared.values.flakeCount = sender.doubleValue.rounded()
        updateMenuState()
    }

    /// Riaprire l'app mentre è già in esecuzione (doppio clic, `open SbuSeasons.app`) apre le Impostazioni.
    /// Utile perché l'icona ❄︎ può finire nascosta dietro il notch se la barra dei menu è piena.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openSettings()
        return true
    }

    private func aboutItem() -> NSMenuItem {
        let item = NSMenuItem(title: String(localized: "Informazioni su \(SbuSeasonsApp.name)"), action: #selector(showAbout), keyEquivalent: "")
        item.target = self
        return item
    }

    /// Il pannello standard, con i credits a Simone Antoniciello (Credits.swift).
    @objc private func showAbout() {
        NSApp.activate()   // app senza Dock: senza, il pannello resta dietro alle altre finestre
        NSApp.orderFrontStandardAboutPanel(options: [.credits: Credits.aboutPanel])
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
