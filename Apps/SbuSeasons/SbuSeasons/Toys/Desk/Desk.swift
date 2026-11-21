import AppKit

/// «Decora» (SBU-187): le decorazioni libere sulla scrivania, una `DeskPanel` per decorazione, su tutti gli schermi.
/// Si salvano con alberi e pupazzi (`KeptToys.desk`, ogni `Tuning.keepInterval`) e valgono tutto l'anno.
/// Fiamme e lampadine si muovono `Tuning.deskFlickerFPS` volte al secondo, solo se `animates`.
final class Desk {
    private(set) var items: [DeskItem] = []
    private var panels: [UUID: DeskPanel] = [:]
    /// Gli schermi: chiave (`NSScreen.wallpaperKey`) e cornice in coordinate globali; il primo è il principale.
    private var screens: [(key: String, frame: CGRect)] = []
    private var timer: Timer?
    private var phase: CGFloat = 0
    /// Aggiunta, rimozione, fine di un trascinamento: da salvare subito, anche a effetto spento (QA SBU-188).
    var onChange: (() -> Void)?

    /// false con Riduci movimento, a batteria e con i giochi in pausa: fiamme e lampadine stanno ferme.
    var animates = true {
        didSet {
            guard animates != oldValue else { return }
            updateTimer()
        }
    }

    /// Schermi nuovi (all'avvio, collegando un monitor): ogni decorazione torna sul suo, o dentro il principale.
    func use(screens: [(key: String, frame: CGRect)]) {
        self.screens = screens
        restore(items)
    }

    /// Rimette le decorazioni salvate.
    func restore(_ saved: [DeskItem]) {
        guard let main = screens.first else { return }
        items = saved.map { item in
            let screen = screens.first { $0.key == item.screen } ?? main
            return item.placed(on: screen.key, size: screen.frame.size)
        }
        rebuildPanels()
    }

    /// Una decorazione nuova attorno al punto `point` (coordinate globali, di norma il cursore).
    func add(_ kind: DeskItem.Kind, at point: CGPoint) {
        guard let screen = screens.first(where: { $0.frame.contains(point) }) ?? screens.first else { return }
        let local = CGPoint(x: point.x - screen.frame.minX, y: point.y - screen.frame.minY)
        let half = kind.size.width / 2
        let item = kind == .lights
            ? DeskItem(kind: kind, screen: screen.key, start: CGPoint(x: local.x - half, y: local.y), end: CGPoint(x: local.x + half, y: local.y))
            : DeskItem(kind: kind, screen: screen.key, center: local)
        items = DeskItem.adding(item.placed(on: screen.key, size: screen.frame.size), to: items)
        rebuildPanels()
        onChange?()
    }

    /// Una decorazione ricevuta in un file (SBU-200): nuova, in mezzo allo schermo principale, e compare piano.
    func receive(_ item: DeskItem) {
        guard let main = screens.first else { return }
        let arrived = item.arriving(on: main.key, size: main.frame.size)
        items = DeskItem.adding(arrived, to: items)
        rebuildPanels()
        if let panel = panels[arrived.id] {
            // Sulla scrivania sta dietro le finestre: per qualche secondo sta sopra, se no chi la riceve non la vede.
            let desktop = panel.level
            panel.level = .floating
            panel.alphaValue = 0
            NSAnimationContext.runAnimationGroup { context in
                context.duration = Tuning.receivedFadeIn
                panel.animator().alphaValue = 1
            }
            Task {
                try? await Task.sleep(for: .seconds(Tuning.receivedFadeIn + Tuning.receivedOnTop))
                panel.level = desktop
            }
        }
        onChange?()
    }

    func remove(_ id: UUID) {
        items.removeAll { $0.id == id }
        rebuildPanels()
        onChange?()
    }

    /// "Togli le decorazioni".
    func removeAll() {
        items = []
        rebuildPanels()
        onChange?()
    }

    /// Fine di un trascinamento: se è finita su un altro schermo passa a quello (il pannello si rifà con la sua origine).
    private func dropped(_ id: UUID) {
        items = DeskItem.settling(id, in: items, screens: screens)
        rebuildPanels()
        onChange?()
    }

    // MARK: - Pannelli

    private func rebuildPanels() {
        let ids = Set(items.map(\.id))
        for (id, panel) in panels where !ids.contains(id) {
            panel.orderOut(nil)
            panels[id] = nil
        }
        for item in items {
            let origin = screens.first { $0.key == item.screen }?.frame.origin ?? .zero
            if let panel = panels[item.id], panel.view.screenOrigin == origin {
                panel.view.item = item
                panel.place()
                continue
            }
            panels[item.id]?.orderOut(nil)
            let panel = DeskPanel(item: item, screenOrigin: origin)
            panel.view.onChange = { [weak self, weak panel] changed in
                guard let self, let panel, let i = self.items.firstIndex(where: { $0.id == changed.id }) else { return }
                self.items[i] = changed
                panel.place()
            }
            panel.view.onRemove = { [weak self] in self?.remove(item.id) }
            panel.view.onDrop = { [weak self] in self?.dropped(item.id) }
            panel.orderFrontRegardless()
            panels[item.id] = panel
        }
        updateTimer()
    }

    private func updateTimer() {
        let needed = animates && items.contains { $0.kind.flickers }
        if !needed {
            timer?.invalidate()
            timer = nil
            phase = 0
            panels.values.forEach { $0.view.phase = 0 }
            return
        }
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1 / Tuning.deskFlickerFPS, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.flicker() }
        }
    }

    private func flicker() {
        phase += CGFloat(1 / Tuning.deskFlickerFPS)
        for panel in panels.values where panel.view.item.kind.flickers { panel.view.phase = phase }
    }
}
