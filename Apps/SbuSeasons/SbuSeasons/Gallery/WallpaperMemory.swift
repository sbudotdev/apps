import Foundation

/// Lo sfondo che l'utente aveva prima di usare la galleria, uno per schermo (per nome).
struct WallpaperMemory {
    private static let key = "originalWallpapers"
    var defaults: UserDefaults = .standard

    private var saved: [String: String] { defaults.dictionary(forKey: Self.key) as? [String: String] ?? [:] }

    /// Solo la prima volta: dopo, sullo schermo c'è già uno dei nostri.
    func remember(_ url: URL, screen: String) {
        guard saved[screen] == nil else { return }
        defaults.set(saved.merging([screen: url.absoluteString]) { old, _ in old }, forKey: Self.key)
    }

    func original(screen: String) -> URL? { saved[screen].flatMap(URL.init(string:)) }

    func forget(screen: String) {
        var all = saved
        all[screen] = nil
        defaults.set(all, forKey: Self.key)
    }
}
