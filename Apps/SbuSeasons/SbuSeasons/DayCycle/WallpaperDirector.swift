import AppKit

/// Chi cambia davvero gli sfondi: dalla galleria, con l'ora del giorno (una volta al minuto e al risveglio)
/// e quando cambia l'effetto, se "Lo sfondo segue l'effetto" è acceso. Uno per tutti gli schermi.
@MainActor
final class WallpaperDirector {
    static let shared = WallpaperDirector()
    let prefs: WallpaperPrefs
    private var timer: Timer?

    init(prefs: WallpaperPrefs = .shared) {
        self.prefs = prefs
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: Tuning.momentCheckInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        // Dopo lo stop il timer è rimasto indietro: si guarda subito che ora è.
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        Settings.shared.observeSeason { [weak self] in self?.followEffect() }
        refresh()
    }

    /// Ora del giorno: rimette su ogni schermo il nostro sfondo nel momento giusto.
    func refresh() {
        for screen in NSScreen.screens {
            guard let id = prefs.chosen[screen.wallpaperKey], let wallpaper = Wallpaper.named(id),
                  Wallpaper.isOurs(NSWorkspace.shared.desktopImageURL(for: screen), folder: Wallpaper.installFolder)
            else { continue }   // l'utente ha messo un suo sfondo: resta il suo
            Task { try? await set(wallpaper, on: [screen]) }
        }
    }

    /// "Lo sfondo segue l'effetto": su tutti gli schermi lo sfondo consigliato, se ce n'è uno.
    func followEffect() {
        guard prefs.followsEffect else { return }
        let season = Settings.shared.seasonID
        for screen in NSScreen.screens {
            let current = prefs.chosen[screen.wallpaperKey].flatMap(Wallpaper.named)
            guard let wallpaper = Wallpaper.suggested(for: season, current: current), wallpaper.id != current?.id else { continue }
            Task { try? await set(wallpaper, on: [screen]) }
        }
    }

    /// Mette lo sfondo nel momento di adesso, ricordando quello dell'utente la prima volta (`WallpaperMemory`).
    func set(_ wallpaper: Wallpaper, on screens: [NSScreen], memory: WallpaperMemory = WallpaperMemory()) async throws {
        let moment = prefs.choice.moment(at: .now)
        let folder = Wallpaper.installFolder
        for screen in screens {
            let key = screen.wallpaperKey
            // Subito, prima del file: un cambio d'effetto che arriva intanto vede già lo sfondo nuovo.
            prefs.chosen[key] = wallpaper.id
            guard let source = wallpaper.url(for: screen.frame.size) else { continue }
            let file = try await Task.detached(priority: .utility) {
                try Wallpaper.prepare(source, moment: moment, in: folder)
            }.value
            let current = NSWorkspace.shared.desktopImageURL(for: screen)
            guard current != file else { continue }   // stesso momento: niente da riscrivere
            if let current, !Wallpaper.isOurs(current, folder: folder) { memory.remember(current, screen: key) }
            try NSWorkspace.shared.setDesktopImageURL(file, for: screen)
        }
    }

    /// "Lascia il mio schermo com'è": torna lo sfondo di prima e smette di cambiarlo con l'ora.
    func restore(on screens: [NSScreen], memory: WallpaperMemory = WallpaperMemory()) throws {
        for screen in screens {
            guard let original = memory.original(screen: screen.wallpaperKey) else { continue }
            try NSWorkspace.shared.setDesktopImageURL(original, for: screen)
            memory.forget(screen: screen.wallpaperKey)
            prefs.chosen[screen.wallpaperKey] = nil
        }
    }
}
