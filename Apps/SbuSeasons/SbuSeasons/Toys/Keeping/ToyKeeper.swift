import Foundation

/// Salva e rilegge `KeptToys` in UserDefaults, come le impostazioni: niente esce dal Mac.
/// `AppDelegate` salva ogni `Tuning.keepInterval` (solo se qualcosa è cambiato), quando ricrea gli schermi e all'uscita.
final class ToyKeeper {
    private static let key = "keptToys"
    private let defaults: UserDefaults
    private var last: KeptToys?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> KeptToys {
        defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(KeptToys.self, from: $0) } ?? KeptToys()
    }

    /// Scrive solo se è cambiato dall'ultima volta. true = scritto.
    @discardableResult
    func save(_ kept: KeptToys) -> Bool {
        guard kept != last, let data = try? JSONEncoder().encode(kept) else { return false }
        defaults.set(data, forKey: Self.key)
        last = kept
        return true
    }
}
