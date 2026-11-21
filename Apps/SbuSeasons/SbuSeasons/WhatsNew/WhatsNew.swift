import Foundation

/// «Novità»: dopo un aggiornamento, la prima volta che si apre il menu ❄︎ c'è una schedina con le novità.
/// Una per versione (2.1, 2.2…): le correzioni (2.1.1) non ne hanno una loro.
nonisolated enum WhatsNew {
    /// Le novità di ogni versione, nell'ordine in cui si leggono. Una riga per cosa nuova, frasi brevi.
    static let notes: [String: [String]] = [
        "2.1": [
            String(localized: "Meteo nuovo: foglie, petali, lucciole, arcobaleno, vento che gira, «Meteo a caso» e «Segui la stagione».", bundle: .seasons),
            String(localized: "Un albero da decorare, pupazzi da vestire che si ricordano, visitatori e Decora sulla scrivania.", bundle: .seasons),
            String(localized: "Gli sfondi cambiano con l'ora: alba, mattina, tramonto, notte e gli altri momenti.", bundle: .seasons),
            String(localized: "Lo sfondo può seguire l'effetto, su tutti gli schermi.", bundle: .seasons),
            String(localized: "Il salvaschermo con gli sfondi del borgo: lo installi dalle Impostazioni.", bundle: .seasons),
        ],
    ]

    /// `2.1.3` → `2.1`.
    static func release(of version: String) -> String {
        version.split(separator: ".").prefix(2).joined(separator: ".")
    }

    /// La versione di cui mostrare le novità, o nil. `seen`: l'ultima vista; `firstRun`: prima apertura dell'app
    /// (c'è il tour, e non è un aggiornamento).
    static func pending(version: String, seen: String?, firstRun: Bool) -> String? {
        let release = release(of: version)
        guard !firstRun, seen != release, notes[release]?.isEmpty == false else { return nil }
        return release
    }
}
