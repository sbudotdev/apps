import Foundation

/// Intensità della nevicata.
nonisolated enum Density: Int, CaseIterable {
    case light, medium, heavy

    var title: String {
        switch self {
        case .light:  return String(localized: "Leggera")
        case .medium: return String(localized: "Media")
        case .heavy:  return String(localized: "Forte")
        }
    }

    /// Numero di fiocchi per uno schermo di riferimento da 1440×900 punti.
    /// Su schermi più grandi o più piccoli il numero viene scalato in proporzione all'area.
    var flakesPerReferenceScreen: Double {
        switch self {
        case .light:  return 120
        case .medium: return 260
        case .heavy:  return 480
        }
    }
}
