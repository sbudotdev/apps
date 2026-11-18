import Foundation

/// Lo sfondo che l'utente aveva prima di usare la galleria, uno per schermo (`NSScreen.wallpaperKey`).
struct WallpaperMemory {
    private static let key = "originalWallpapers"
    var defaults: UserDefaults = .standard

    private var saved: [String: String] { defaults.dictionary(forKey: Self.key) as? [String: String] ?? [:] }

    /// Sempre l'ultimo sfondo dell'utente: i nostri li scarta già `Wallpaper.set`.
    func remember(_ url: URL, screen: String) {
        defaults.set(saved.merging([screen: url.absoluteString]) { _, new in new }, forKey: Self.key)
    }

    func original(screen: String) -> URL? { saved[screen].flatMap(URL.init(string:)) }

    func forget(screen: String) {
        var all = saved
        all[screen] = nil
        defaults.set(all, forKey: Self.key)
    }
}
