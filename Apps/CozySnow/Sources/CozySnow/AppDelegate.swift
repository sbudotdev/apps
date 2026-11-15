import AppKit

/// Crea una finestra di neve per ogni schermo e gestisce il menu ❄︎ nella barra dei menu.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var overlays: [SnowOverlayWindow] = []
    private var statusItem: NSStatusItem?

    private var isSnowing = true
    private var density: Density = .medium

    private lazy var toggleItem = NSMenuItem(title: "Fai nevicare", action: nil, keyEquivalent: "s")
    private var densityItems: [NSMenuItem] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        rebuildOverlays()

        // Se colleghi/scolleghi un monitor o cambi risoluzione, ricreiamo le finestre.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    // MARK: - Finestre

    @objc private func screensDidChange() {
        rebuildOverlays()
    }

    private func rebuildOverlays() {
        overlays.forEach { $0.close() }
        overlays = NSScreen.screens.map { SnowOverlayWindow(screen: $0, density: density) }
        overlays.forEach { $0.setSnowing(isSnowing) }
    }

    // MARK: - Menu

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "snowflake", accessibilityDescription: "CozySnow")

        let menu = NSMenu()

        toggleItem.target = self
        toggleItem.action = #selector(toggleSnow)
        menu.addItem(toggleItem)

        menu.addItem(.separator())

        let densityHeader = NSMenuItem(title: "Intensità", action: nil, keyEquivalent: "")
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
        menu.addItem(NSMenuItem(title: "Esci", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        item.menu = menu
        statusItem = item
        updateMenuState()
    }

    private func updateMenuState() {
        toggleItem.state = isSnowing ? .on : .off
        for mi in densityItems {
            mi.state = (mi.tag == density.rawValue) ? .on : .off
        }
    }

    @objc private func toggleSnow() {
        isSnowing.toggle()
        overlays.forEach { $0.setSnowing(isSnowing) }
        updateMenuState()
    }

    @objc private func selectDensity(_ sender: NSMenuItem) {
        guard let newDensity = Density(rawValue: sender.tag) else { return }
        density = newDensity
        overlays.forEach { $0.density = newDensity }
        updateMenuState()
    }
}
