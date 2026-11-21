import Foundation

/// Gli otto momenti del giorno di uno sfondo, nell'ordine in cui arrivano. Ognuno comincia a un'ora fissa
/// (`Tuning.momentStarts`): l'ora è quella del Mac, senza posizione né rete.
nonisolated enum DayMoment: String, CaseIterable, Codable, Sendable {
    case dawn, sunrise, morning, noon, goldenHour, sunset, dusk, night

    /// Il momento all'ora del Mac (`hour` 0…23, `minute` 0…59).
    static func at(hour: Int, minute: Int) -> DayMoment {
        let time = Double(hour) + Double(minute) / 60
        // Prima dell'alba è ancora notte: l'ultimo momento iniziato, oppure la notte di ieri.
        return allCases.last { Tuning.momentStarts[$0, default: 0] <= time } ?? .night
    }

    static func at(_ date: Date, calendar: Calendar = .current) -> DayMoment {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return at(hour: parts.hour ?? 12, minute: parts.minute ?? 0)
    }

    var title: String {
        switch self {
        case .dawn: String(localized: "Alba", bundle: .seasons)
        case .sunrise: String(localized: "Aurora", bundle: .seasons)
        case .morning: String(localized: "Mattina", bundle: .seasons)
        case .noon: String(localized: "Mezzogiorno", bundle: .seasons)
        case .goldenHour: String(localized: "Ora d'oro", bundle: .seasons)
        case .sunset: String(localized: "Tramonto", bundle: .seasons)
        case .dusk: String(localized: "Crepuscolo", bundle: .seasons)
        case .night: String(localized: "Notte", bundle: .seasons)
        }
    }
}
