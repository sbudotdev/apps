import Foundation

/// Intensità della nevicata.
enum Density: Int, CaseIterable {
    case light, medium, heavy

    var title: String {
        switch self {
        case .light:  return "Leggera"
        case .medium: return "Media"
        case .heavy:  return "Forte"
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
