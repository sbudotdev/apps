import AppKit

/// Chi cambia davvero gli sfondi: dalla galleria, con l'ora del giorno e quando cambia l'effetto,
/// se "Lo sfondo segue l'effetto" è acceso. Uno per tutti gli schermi.
/// Con «Segue l'ora del Mac» mette l'HEIC dinamico e il cambio lo fa macOS; il timer parte solo se quel file non si fa.
@MainActor
final class WallpaperDirector {
    static let shared = WallpaperDirector()
    let prefs: WallpaperPrefs
    private var timer: Timer?
    /// Il momento dell'ultimo giro: il timer agisce solo quando ne comincia un altro.
    private var lastMoment: DayMoment?
    /// Il file che abbiamo messo su ogni schermo (`wallpaperKey`): se macOS lo perde, si rimette.
    private var placed: [String: URL] = [:]

    init(prefs: WallpaperPrefs = .shared) {
        self.prefs = prefs
    }

    func start() {
        // Al risveglio o cambiando schermo macOS a volte perde lo sfondo: si rimette, solo dove c'era uno dei nostri.
        NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.bringBack(); self?.refresh() }
        }
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.bringBack() }
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

    /// Rimette il nostro sfondo dove macOS l'ha perso (`Wallpaper.wasLost`).
    func bringBack() {
        let plan = NSScreen.screens.compactMap { screen -> (Wallpaper, NSScreen)? in
            let key = screen.wallpaperKey
            guard let id = prefs.chosen[key], let wallpaper = Wallpaper.named(id),
                  Wallpaper.wasLost(placed: placed[key], current: NSWorkspace.shared.desktopImageURL(for: screen),
                                    folder: Wallpaper.installFolder)
            else { return nil }
            return (wallpaper, screen)
        }
        apply(plan)
    }

    /// Il ripiego: un controllo al minuto, solo se l'HEIC dinamico non si è potuto fare.
    private func startClock() {
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: Tuning.momentCheckInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh(onlyIfChanged: true) }
        }
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

    /// Mette lo sfondo (dinamico o nel momento fisso), ricordando quello dell'utente la prima volta (`WallpaperMemory`).
    func set(_ wallpaper: Wallpaper, on screens: [NSScreen], memory: WallpaperMemory = WallpaperMemory()) async throws {
        let choice = prefs.choice
        let folder = Wallpaper.installFolder
        for screen in screens {
            let key = screen.wallpaperKey
            // Subito, prima del file: un cambio d'effetto che arriva intanto vede già lo sfondo nuovo.
            prefs.chosen[key] = wallpaper.id
            guard let source = wallpaper.url(for: screen.frame.size) else { continue }
            let (file, dynamic) = try await Task.detached(priority: .utility) {
                do {
                    return (try Wallpaper.prepare(source, choice: choice, at: .now, in: folder), choice == .automatic)
                } catch where choice == .automatic {
                    // L'HEIC non si fa (disco pieno, codec): il momento di adesso in JPEG, e il timer lo cambia.
                    return (try Wallpaper.prepare(source, moment: choice.moment(at: .now), in: folder), false)
                }
            }.value
            if choice == .automatic, !dynamic { startClock() }
            let current = NSWorkspace.shared.desktopImageURL(for: screen)
            if current != file {   // stesso file: niente da riscrivere
                if let current, !Wallpaper.isOurs(current, folder: folder) { memory.remember(current, screen: key) }
                try NSWorkspace.shared.setDesktopImageURL(file, for: screen)
            }
            placed[key] = file
        }
    }

    /// "Lascia il mio schermo com'è": torna lo sfondo di prima e smette di cambiarlo con l'ora.
    func restore(on screens: [NSScreen], memory: WallpaperMemory = WallpaperMemory()) throws {
        for screen in screens {
            guard let original = memory.original(screen: screen.wallpaperKey) else { continue }
            try NSWorkspace.shared.setDesktopImageURL(original, for: screen)
            memory.forget(screen: screen.wallpaperKey)
            prefs.chosen[screen.wallpaperKey] = nil
            placed[screen.wallpaperKey] = nil
        }
    }
}
