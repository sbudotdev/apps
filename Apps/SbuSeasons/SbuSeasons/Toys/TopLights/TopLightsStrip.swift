import AppKit

/// Le Luci in alto su tutti gli schermi scelti (SBU-229): una `TopLightsPanel` per schermo, accese dal menu ❄︎ → Decora
/// o dalle Impostazioni. Valgono con ogni effetto e anche a effetto spento; seguono gli schermi della SBU-227.
final class TopLightsStrip {
    private var panels: [String: TopLightsPanel] = [:]
    private var timer: Timer?
    private let start = ProcessInfo.processInfo.systemUptime

    /// Accende, spegne e aggiorna le luci; costa poco se non cambia niente (si chiama 8 volte al secondo).
    /// `screens`: chiave (`NSScreen.wallpaperKey`), cornice e dove finisce la barra dei menu, in coordinate globali.
    /// `animates` false (Riduci movimento, batteria, giochi in pausa, videogioco): luci fisse.
    func update(screens: [(key: String, frame: CGRect, menuBarBottom: CGFloat)], values: SnowSettings, animates: Bool) {
        let connected = screens.map(\.key)
        let shown = values.topLights ? screens.filter { values.showsEffect(onScreen: $0.key, connected: connected) } : []
        let keys = Set(shown.map(\.key))
        for (key, panel) in panels where !keys.contains(key) {
            panel.orderOut(nil)
            panels[key] = nil
        }
        let animation = TopLights.animation(values.topLightsAnimation, reduceMotion: !animates)
        for screen in shown {
            let frame = CGRect(x: screen.frame.minX, y: screen.menuBarBottom - Tuning.topLightsHeight,
                               width: screen.frame.width, height: Tuning.topLightsHeight)
            let panel = panels[screen.key] ?? TopLightsPanel()
            if panel.frame != frame { panel.setFrame(frame, display: false) }
            panel.view.palette = values.topLightsPalette
            panel.view.single = values.topLightsColor
            panel.view.shape = values.topLightsShape
            panel.view.animation = animation
            if panels[screen.key] == nil {
                panel.orderFrontRegardless()
                panels[screen.key] = panel
            }
        }
        updateTimer(needed: !panels.isEmpty && animation.moves)
    }

    private func updateTimer(needed: Bool) {
        guard needed else {
            timer?.invalidate()
            timer = nil
            return
        }
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1 / Tuning.topLightsFPS, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    private func tick() {
        let time = ProcessInfo.processInfo.systemUptime - start
        panels.values.forEach { $0.view.time = time }
    }
}
