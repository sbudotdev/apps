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

    /// "Prima il Dock": lo spazzaneve parte dal Dock (se no dalla finestra più in alto).
    private var ploughDockFirst: Bool {
        get { UserDefaults.standard.object(forKey: "ploughDockFirst") as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: "ploughDockFirst") }
    }

    private lazy var toggleItem = NSMenuItem(title: String(localized: "Mostra l'effetto"), action: nil, keyEquivalent: "s")
    private var behindItem: NSMenuItem?
    private var soundsItem: NSMenuItem?
    private var nightItems: [NSMenuItem] = []
    private var densityItems: [NSMenuItem] = []
    /// L'intensità continua, sotto Leggera/Media/Forte: è lo stesso valore di "Quantità" nelle Impostazioni.
    private lazy var intensitySlider: NSSlider = {
        let slider = NSSlider(value: Settings.shared.values.flakeCount, minValue: Density.range.lowerBound,
                              maxValue: Density.range.upperBound, target: self, action: #selector(intensityChanged(_:)))
        slider.isContinuous = true
        slider.controlSize = .small
        slider.setAccessibilityLabel(String(localized: "Intensità"))
        return slider
    }()
    private var seasonItems: [NSMenuItem] = []
    /// I giochi d'inverno: spenti nelle altre stagioni.
    private var winterItems: [NSMenuItem] = []
    private var dockFirstItem: NSMenuItem?
    private var cableCarItem: NSMenuItem?
    private var pauseItem: NSMenuItem?
    /// Le voci dei personaggi, con la spunta se il personaggio c'è.
    private var figureItems: [(item: NSMenuItem, kind: FigureKind)] = []
    private var countdownItem: NSMenuItem?
    /// Il conto alla rovescia per Natale: creato la prima volta che si accende.
    private var countdownPanel: CountdownPanel?

    /// "Conto alla rovescia per Natale" acceso: si ricorda al prossimo avvio.
    private var showsCountdown: Bool {
        get { UserDefaults.standard.bool(forKey: "showsCountdown") }
        set { UserDefaults.standard.set(newValue, forKey: "showsCountdown") }
    }

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

    /// Il tour di benvenuto: creato la prima volta che serve, poi riusato.
    private lazy var tourWindow: NSWindow = {
        let window = NSWindow(contentViewController: makeTour())
        window.title = String(localized: "Tour di benvenuto")
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        return window
    }()

    /// Un tour nuovo, che parte dalla prima pagina.
    private func makeTour() -> NSHostingController<TourView> {
        NSHostingController(rootView: TourView { [weak self] in
            self?.tourWindow.performClose(nil)
        })
    }

    /// La finestra Sfondi: creata la prima volta che serve, poi riusata.
    private lazy var galleryWindow: NSWindow = {
        let window = NSWindow(contentViewController: NSHostingController(rootView: GalleryView()))
        window.title = String(localized: "Sfondi")
        window.styleMask = [.titled, .closable, .resizable]
        window.isReleasedWhenClosed = false
        window.delegate = self
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
        if showsCountdown { setCountdownVisible(true) }
        updateAmbience()
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

        // La prima volta il tour di benvenuto. Poi, aperta a mano (doppio clic, `open`), le Impostazioni.
        // All'avvio automatico al login no: lì vogliamo solo la neve.
        if TourProgress.shared.opensAtLaunch {
            TourProgress.shared.markSeen()
            openTour()
        } else if !launchedAsLoginItem() {
            openSettings()
        }

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
        for overlay in overlays { overlay.scene.onGlobeShaken = { TourProgress.shared.complete(.shakeGlobe) } }
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
        menu.autoenablesItems = false   // i giochi d'inverno si spengono a mano fuori dall'inverno (`updateMenuState`)

        // Nell'ordine: effetto, intensità, giochi, Natale, notte, sfondi, suoni, impostazioni.
        toggleItem.target = self
        toggleItem.action = #selector(toggleSnow)
        menu.addItem(toggleItem)

        // Effetto: un sottomenu con l'elenco di `Seasons.all`.
        let seasonMenu = NSMenu()
        seasonItems = Seasons.all.map { season in
            let mi = NSMenuItem(title: season.title, action: #selector(selectSeason(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = season.id
            mi.image = NSImage(systemSymbolName: season.symbol, accessibilityDescription: nil)
            seasonMenu.addItem(mi)
            return mi
        }
        menu.addItem(submenu(String(localized: "Effetto"), seasonMenu))

        let behind = NSMenuItem(title: String(localized: "Dietro le finestre"), action: #selector(toggleBehindWindows), keyEquivalent: "")
        behind.target = self
        behind.toolTip = String(localized: "Gli effetti restano sulla scrivania, sotto le finestre delle app.")
        menu.addItem(behind)
        behindItem = behind

        let meltItem = NSMenuItem(title: String(localized: "Togli quello che si è posato"), action: #selector(meltSnow), keyEquivalent: "r")
        meltItem.target = self
        menu.addItem(meltItem)

        menu.addItem(.separator())
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
        menu.addItem(submenu(String(localized: "Giochi"), toysMenu()))
        menu.addItem(submenu(String(localized: "Natale"), christmasMenu()))
        menu.addItem(submenu(String(localized: "Notte"), nightMenu()))

        let galleryItem = NSMenuItem(title: String(localized: "Sfondi…"), action: #selector(openGallery), keyEquivalent: "")
        galleryItem.target = self
        galleryItem.toolTip = String(localized: "Dieci sfondi per la scrivania, ognuno con il suo effetto.")
        menu.addItem(galleryItem)

        let sounds = NSMenuItem(title: String(localized: "Suoni"), action: #selector(toggleSounds), keyEquivalent: "")
        sounds.target = self
        sounds.toolTip = String(localized: "Il volume è nelle Impostazioni.")
        menu.addItem(sounds)
        soundsItem = sounds

        menu.addItem(.separator())
        let settingsItem = NSMenuItem(title: String(localized: "Impostazioni…"), action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let tourItem = NSMenuItem(title: String(localized: "Tour di benvenuto…"), action: #selector(openTour), keyEquivalent: "")
        tourItem.target = self
        menu.addItem(tourItem)

        menu.addItem(aboutItem())
        menu.addItem(NSMenuItem(title: String(localized: "Esci da \(SbuSeasonsApp.name)"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        item.menu = menu
        statusItem = item
        updateMenuState()
    }

    /// Una voce con il suo sottomenu. I giochi d'inverno si spengono a mano fuori dall'inverno (`updateMenuState`).
    private func submenu(_ title: String, _ menu: NSMenu) -> NSMenuItem {
        menu.autoenablesItems = false
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.submenu = menu
        return item
    }

    /// Giochi: palle di neve e palla di vetro, poi quelli d'inverno (spazzaneve, slittino, funivia, albero) e i personaggi.
    private func toysMenu() -> NSMenu {
        let menu = NSMenu()
        func item(_ title: String, _ action: Selector, tip: String? = nil) -> NSMenuItem {
            let mi = NSMenuItem(title: title, action: action, keyEquivalent: "")
            mi.target = self
            mi.toolTip = tip
            menu.addItem(mi)
            return mi
        }
        _ = item(String(localized: "Togli le palle di neve"), #selector(clearSnowballs),
                 tip: String(localized: "Per fare una palla di neve, tieni premuto ⌥ e passa il cursore sulla neve posata."))
        // La palla di vetro si scuote anche dal menu: non tutti possono scuotere il mouse.
        _ = item(String(localized: "Scuoti la palla di vetro"), #selector(shakeGlobe))
        menu.addItem(.separator())
        let plough = item(String(localized: "Manda lo spazzaneve"), #selector(sendPlough),
                          tip: String(localized: "Pulisce il bordo su cui corre e scende di bordo in bordo. La neve raccolta resta in una montagnetta."))
        let dockFirst = item(String(localized: "Prima il Dock"), #selector(toggleDockFirst),
                             tip: String(localized: "Acceso: parte dal Dock. Spento: parte dalla finestra più in alto."))
        dockFirst.indentationLevel = 1
        let sled = item(String(localized: "Prepara la pista da slittino"), #selector(setUpSledRun),
                        tip: String(localized: "Lancia lo slittino trascinandolo, o fai clic per spingerlo: scende di bordo in bordo."))
        let cableCar = item(String(localized: "Monta la funivia"), #selector(toggleCableCar),
                            tip: String(localized: "Trascina il gancio sul bordo di una finestra: la cabina corre sul cavo."))
        let tree = item(String(localized: "Pianta un albero di Natale"), #selector(plantTree),
                        tip: String(localized: "Fai clic sui rami per appendere le palline. Trascina l'albero per spostarlo."))
        let clear = item(String(localized: "Togli alberi, neve e slitte"), #selector(clearWinterPlay))
        let pause = item(String(localized: "Metti in pausa i giochi"), #selector(togglePause))
        winterItems = [plough, dockFirst, sled, cableCar, tree, clear, pause]
        dockFirstItem = dockFirst
        cableCarItem = cableCar
        pauseItem = pause

        menu.addItem(.separator())
        // Personaggi: una voce per tipo, che lo mette o lo toglie.
        let figures = NSMenu()
        figureItems = FigureKind.allCases.map { kind in
            let mi = NSMenuItem(title: kind.title, action: #selector(toggleFigure(_:)), keyEquivalent: "")
            mi.target = self
            mi.toolTip = kind.tip
            figures.addItem(mi)
            return (mi, kind)
        }
        let figuresItem = submenu(String(localized: "Personaggi"), figures)
        menu.addItem(figuresItem)
        winterItems.append(figuresItem)
        return menu
    }

    /// Babbo Natale, l'omino di pan di zenzero (solo d'inverno, come i giochi) e il conto alla rovescia (sempre).
    private func christmasMenu() -> NSMenu {
        let menu = NSMenu()
        let santa = NSMenuItem(title: String(localized: "Fai passare Babbo Natale"), action: #selector(sendSanta), keyEquivalent: "")
        santa.toolTip = String(localized: "Dal 1° dicembre al 6 gennaio passa da solo ogni tanto, quando nevica, e la vigilia più spesso. Lascia un regalo al giorno su una finestra o sul Dock: fai clic per aprirlo.")
        let man = NSMenuItem(title: String(localized: "Manda l'omino di pan di zenzero"), action: #selector(sendGingerbreadMan), keyEquivalent: "")
        man.toolTip = String(localized: "Corre lungo il Dock: prova a prenderlo col cursore.")
        let countdown = NSMenuItem(title: String(localized: "Conto alla rovescia per Natale"), action: #selector(toggleCountdown), keyEquivalent: "")
        countdown.toolTip = String(localized: "Un pannellino sulla scrivania con giorni, ore e minuti. Trascinalo dove vuoi.")
        for mi in [santa, man, countdown] {
            mi.target = self
            menu.addItem(mi)
        }
        winterItems += [santa, man]
        countdownItem = countdown
        return menu
    }

    /// Notte: le stesse tre scelte delle Impostazioni. L'ora di inizio resta nelle Impostazioni.
    private func nightMenu() -> NSMenu {
        let menu = NSMenu()
        let titles: [NightMode: String] = [
            .off: String(localized: "Mai"),
            .late: String(localized: "Di sera"),
            .always: String(localized: "Sempre"),
        ]
        nightItems = NightMode.allCases.map { mode in
            let mi = NSMenuItem(title: titles[mode] ?? "", action: #selector(selectNight(_:)), keyEquivalent: "")
            mi.target = self
            mi.representedObject = mode.rawValue
            menu.addItem(mi)
            return mi
        }
        return menu
    }

    private func updateMenuState() {
        toggleItem.state = isSnowing ? .on : .off
        let winter = Settings.shared.season is Snow
        for mi in winterItems { mi.isEnabled = winter }
        dockFirstItem?.state = ploughDockFirst ? .on : .off
        pauseItem?.state = overlays.first?.toysPaused == true ? .on : .off
        for (mi, kind) in figureItems { mi.state = overlays.contains { $0.scene.hasFigure(kind) } ? .on : .off }
        countdownItem?.state = showsCountdown ? .on : .off
        let values = Settings.shared.values
        behindItem?.state = values.behindWindows ? .on : .off
        soundsItem?.state = values.sounds ? .on : .off
        for mi in nightItems { mi.state = mi.representedObject as? String == values.night.rawValue ? .on : .off }
        cableCarItem?.title = overlays.contains(where: \.hasCableCar)
            ? String(localized: "Togli la funivia") : String(localized: "Monta la funivia")
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
        updateAmbience()
        updateMenuState()
    }

    /// Il sottofondo della stagione (vento, pioggia), solo mentre cade qualcosa.
    private func updateAmbience() {
        SoundBoard.shared.setAmbience(isSnowing ? Settings.shared.season.ambience : nil)
    }

    @objc private func toggleBehindWindows() {
        Settings.shared.values.behindWindows.toggle()   // le finestre lo leggono al prossimo fotogramma
        updateMenuState()
    }

    @objc private func toggleSounds() {
        Settings.shared.values.sounds.toggle()
        SoundBoard.shared.settingsChanged()
        updateMenuState()
    }

    @objc private func selectNight(_ sender: NSMenuItem) {
        guard let mode = (sender.representedObject as? String).flatMap(NightMode.init(rawValue:)) else { return }
        Settings.shared.values.night = mode
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

    /// Lo schermo su cui si gioca: quello del cursore (cioè del menu appena usato).
    private var currentOverlay: OverlayWindow? {
        overlays.first { $0.frame.contains(NSEvent.mouseLocation) } ?? overlays.first
    }

    @objc private func sendPlough() {
        // Uno solo in giro, anche con più schermi (ogni scena controlla solo la sua).
        guard !overlays.contains(where: { $0.scene.toys.contains { $0 is Snowplough } }) else { return }
        let overlay = ploughDockFirst ? overlays.first(where: \.hasDock) ?? currentOverlay : currentOverlay
        overlay?.scene.sendPlough(dockFirst: ploughDockFirst)
    }

    @objc private func toggleDockFirst() {
        ploughDockFirst.toggle()
        updateMenuState()
    }

    /// Se c'è (su qualunque schermo) lo toglie, se no lo mette sullo schermo del cursore.
    @objc private func toggleFigure(_ sender: NSMenuItem) {
        guard let kind = figureItems.first(where: { $0.item === sender })?.kind else { return }
        if overlays.contains(where: { $0.scene.hasFigure(kind) }) {
            overlays.filter { $0.scene.hasFigure(kind) }.forEach { $0.scene.toggleFigure(kind) }
        } else {
            currentOverlay?.scene.toggleFigure(kind)
        }
        updateMenuState()
    }

    @objc private func setUpSledRun() { currentOverlay?.scene.setUpSledRun() }
    @objc private func plantTree() { currentOverlay?.scene.plantTree() }
    @objc private func clearWinterPlay() { overlays.forEach { $0.scene.clearWinterPlay() } }

    @objc private func toggleCableCar() {
        if overlays.contains(where: \.hasCableCar) {
            overlays.forEach { $0.scene.removeCableCar() }
        } else {
            currentOverlay?.scene.setUpCableCar()
        }
        updateMenuState()
    }

    @objc private func sendSanta() {
        // Uno alla volta, anche con più schermi.
        guard !overlays.contains(where: { $0.scene.santa != nil }) else { return }
        currentOverlay?.scene.sendSanta()
    }

    @objc private func sendGingerbreadMan() {
        (overlays.first(where: \.hasDock) ?? currentOverlay)?.scene.sendGingerbreadMan()
    }

    @objc private func toggleCountdown() {
        showsCountdown.toggle()
        setCountdownVisible(showsCountdown)
        updateMenuState()
    }

    private func setCountdownVisible(_ visible: Bool) {
        if visible {
            if countdownPanel == nil { countdownPanel = CountdownPanel() }
            countdownPanel?.orderFrontRegardless()
        } else {
            countdownPanel?.orderOut(nil)
        }
    }

    @objc private func togglePause() {
        let paused = !(overlays.first?.toysPaused ?? false)
        overlays.forEach { $0.scene.toysPaused = paused }
        updateMenuState()
    }

    @objc private func selectSeason(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        Settings.shared.seasonID = id   // il resto lo fa seasonDidChange
    }

    private func seasonDidChange() {
        TourProgress.shared.complete(.changeEffect)
        let season = Settings.shared.season
        overlays.forEach { $0.setSeason(season) }
        updateAmbience()
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

    @objc private func openTour() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        // riaperto dopo Inizia o Salta: ricomincia dalla prima pagina, non da dove era rimasto
        if !tourWindow.isVisible { tourWindow.contentViewController = makeTour() }
        tourWindow.makeKeyAndOrderFront(nil)
        tourWindow.orderFrontRegardless()
    }

    @objc private func openGallery() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate()
        galleryWindow.makeKeyAndOrderFront(nil)
        galleryWindow.orderFrontRegardless()
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
        // Via dal Dock quando si chiude l'ultima delle nostre finestre: resta solo la neve.
        let closing = notification.object as? NSWindow
        // NSApp.windows e non le lazy var: leggerle creerebbe una finestra mai aperta.
        guard !NSApp.windows.contains(where: { $0 !== closing && $0.isVisible && $0.delegate === self }) else { return }
        NSApp.setActivationPolicy(.accessory)
    }

    /// macOS segnala nell'evento di avvio se l'app è partita come elemento di login.
    private func launchedAsLoginItem() -> Bool {
        let event = NSAppleEventManager.shared().currentAppleEvent
        return event?.eventID == kAEOpenApplication
            && event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
    }
}
