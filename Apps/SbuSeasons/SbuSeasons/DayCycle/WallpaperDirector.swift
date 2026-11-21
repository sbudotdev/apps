import AppKit

/// Chi cambia davvero gli sfondi: dalla galleria, con l'ora del giorno (una volta al minuto e al risveglio)
/// e quando cambia l'effetto, se "Lo sfondo segue l'effetto" è acceso. Uno per tutti gli schermi.
@MainActor
final class WallpaperDirector {
    static let shared = WallpaperDirector()
    let prefs: WallpaperPrefs
    private var timer: Timer?
    /// Il momento dell'ultimo giro: il timer agisce solo quando ne comincia un altro.
    private var lastMoment: DayMoment?

    init(prefs: WallpaperPrefs = .shared) {
        self.prefs = prefs
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: Tuning.momentCheckInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh(onlyIfChanged: true) }
        }
        // Dopo lo stop il timer è rimasto indietro: si guarda subito che ora è.
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        Settings.shared.observeSeason { [weak self] in self?.followEffect() }
        refresh()
    }

    /// Ora del giorno: rimette su ogni schermo il nostro sfondo nel momento giusto.
    /// `onlyIfChanged`: dal timer, che passa ogni minuto; non rilegge niente finché il momento è lo stesso.
    func refresh(onlyIfChanged: Bool = false) {
        let moment = prefs.choice.moment(at: .now)
        guard !onlyIfChanged || moment != lastMoment else { return }
        lastMoment = moment
        let plan = NSScreen.screens.compactMap { screen -> (Wallpaper, NSScreen)? in
            guard let id = prefs.chosen[screen.wallpaperKey], let wallpaper = Wallpaper.named(id),
                  Wallpaper.isOurs(NSWorkspace.shared.desktopImageURL(for: screen), folder: Wallpaper.installFolder)
            else { return nil }   // l'utente ha messo un suo sfondo: resta il suo
            return (wallpaper, screen)
        }
        apply(plan, retryOnFailure: true)
    }

    /// "Lo sfondo segue l'effetto": su tutti gli schermi lo sfondo consigliato, se ce n'è uno.
    func followEffect() {
        guard prefs.followsEffect else { return }
        let season = Settings.shared.seasonID
        let plan = NSScreen.screens.compactMap { screen -> (Wallpaper, NSScreen)? in
            let current = prefs.chosen[screen.wallpaperKey].flatMap(Wallpaper.named)
            guard let wallpaper = Wallpaper.suggested(for: season, current: current), wallpaper.id != current?.id else { return nil }
            return (wallpaper, screen)
        }
        apply(plan)
    }

    /// Un solo `Task` e uno sfondo alla volta: due schermi con lo stesso sfondo non scrivono lo stesso JPEG insieme.
    /// `retryOnFailure`: se un cambio fallisce, il timer ci riprova al giro dopo invece di aspettare il momento seguente.
    private func apply(_ plan: [(Wallpaper, NSScreen)], retryOnFailure: Bool = false) {
        guard !plan.isEmpty else { return }
        let groups = Dictionary(grouping: plan, by: { $0.0.id })
        Task {
            for pairs in groups.values {
                do {
                    try await set(pairs[0].0, on: pairs.map(\.1))
                } catch {
                    if retryOnFailure { lastMoment = nil }
                }
            }
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
