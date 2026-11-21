import Foundation

/// Le scelte sugli sfondi (Impostazioni → Sfondi), salvate a parte da `SnowSettings`: "Ripristina…" non tocca gli sfondi.
@Observable
final class WallpaperPrefs {
    static let shared = WallpaperPrefs()
    @ObservationIgnored private let defaults: UserDefaults

    /// Ora del giorno: automatica o fissa su un momento.
    var choice: MomentChoice {
        didSet { defaults.set(choice.rawValue, forKey: "wallpaperMoment") }
    }

    /// Cambiando effetto (dal menu, dalle Impostazioni o dal meteo a caso) arriva lo sfondo consigliato.
    var followsEffect: Bool {
        didSet { defaults.set(followsEffect, forKey: "wallpaperFollowsEffect") }
    }

    /// Il nostro sfondo su ogni schermo (`NSScreen.wallpaperKey` → `Wallpaper.id`): è quello che cambia con l'ora.
    var chosen: [String: String] {
        didSet { defaults.set(chosen, forKey: "chosenWallpapers") }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        choice = MomentChoice(rawValue: defaults.string(forKey: "wallpaperMoment") ?? "")
        followsEffect = defaults.bool(forKey: "wallpaperFollowsEffect")
        chosen = defaults.dictionary(forKey: "chosenWallpapers") as? [String: String] ?? [:]
    }
}
