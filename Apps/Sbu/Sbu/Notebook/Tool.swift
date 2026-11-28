import Foundation

/// A tool the notebook can hold: one of the sbu.dev apps, as a page (ADR-0027).
nonisolated enum Tool: String, CaseIterable, Identifiable {
    case level, moon, subscriptions

    var id: Self { self }

    /// What the page is called: what the tool is for, not the app's name.
    var name: LocalizedStringResource {
        switch self {
        case .level: "Livella"
        case .moon: "Luna"
        case .subscriptions: "Abbonamenti"
        }
    }

    /// The one thing it does, under the name.
    var summary: LocalizedStringResource {
        switch self {
        case .level: "Misura l'inclinazione"
        case .moon: "La fase di oggi e le prossime"
        case .subscriptions: "Quanto spendi e quando"
        }
    }

    var symbol: String {
        switch self {
        case .level: "level"
        case .moon: "moon"
        case .subscriptions: "creditcard"
        }
    }

    /// The tool a link opens: `sbu://level`.
    init?(url: URL) {
        guard url.scheme == "sbu", let host = url.host() else { return nil }
        self.init(rawValue: host)
    }
}
