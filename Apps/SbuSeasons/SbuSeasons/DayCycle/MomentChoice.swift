import Foundation

/// Impostazioni → Sfondi → Ora del giorno: lo sfondo segue l'ora del Mac, oppure resta su un momento.
nonisolated enum MomentChoice: Hashable, Sendable {
    case automatic
    case fixed(DayMoment)

    /// Salvato come `automatic` o come il nome del momento; un valore sconosciuto torna automatico.
    init(rawValue: String) {
        self = DayMoment(rawValue: rawValue).map(MomentChoice.fixed) ?? .automatic
    }

    var rawValue: String {
        switch self {
        case .automatic: "automatic"
        case .fixed(let moment): moment.rawValue
        }
    }

    func moment(at date: Date, calendar: Calendar = .current) -> DayMoment {
        switch self {
        case .automatic: DayMoment.at(date, calendar: calendar)
        case .fixed(let moment): moment
        }
    }

    /// Le voci del menu a comparsa, nell'ordine: Automatica, poi gli otto momenti.
    static let all: [MomentChoice] = [.automatic] + DayMoment.allCases.map(MomentChoice.fixed)

    var title: String {
        switch self {
        case .automatic: String(localized: "Segue l'ora del Mac", bundle: .seasons)
        case .fixed(let moment): moment.title
        }
    }
}
