import Foundation

/// Le opzioni del salvaschermo, salvate nelle sue preferenze (`ScreenSaverDefaults`): il salvaschermo gira in un
/// processo di macOS che non legge le impostazioni dell'app.
nonisolated struct SaverOptions: Equatable {
    /// Lo sfondo scelto; nil = uno diverso ogni volta.
    var wallpaperID: String?
    /// L'effetto consigliato dello sfondo, sopra l'immagine.
    var showsEffect = true
    /// L'ultimo mostrato: "uno diverso ogni volta" non lo ripete.
    var previousID: String?

    init(defaults: UserDefaults) {
        wallpaperID = defaults.string(forKey: "wallpaper")
        showsEffect = defaults.object(forKey: "showsEffect") as? Bool ?? true
        previousID = defaults.string(forKey: "previous")
    }

    func save(to defaults: UserDefaults) {
        defaults.set(wallpaperID, forKey: "wallpaper")
        defaults.set(showsEffect, forKey: "showsEffect")
        defaults.set(previousID, forKey: "previous")
        defaults.synchronize()   // ScreenSaverDefaults: senza, il processo del salvaschermo può chiudersi prima di scrivere
    }

    /// Lo sfondo di questa volta: quello scelto, oppure uno a caso diverso da `previous`.
    @MainActor
    static func pick(chosen: String?, previous: String?) -> Wallpaper {
        if let chosen, let wallpaper = Wallpaper.named(chosen) { return wallpaper }
        let others = Wallpaper.all.filter { $0.id != previous }
        return others.randomElement() ?? Wallpaper.all[0]
    }
}
