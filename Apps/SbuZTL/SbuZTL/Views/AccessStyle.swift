import SbuKit
import SwiftUI

/// The word, symbol and color of an answer. Color never stands alone.
extension Access {
    var headline: LocalizedStringKey {
        switch self {
        case .off: "Zona non attiva"
        case .allowed: "Puoi entrare"
        case .paid: "Puoi entrare pagando"
        case .forbidden: "Non puoi entrare"
        case .unknown: "Non lo so"
        }
    }

    var symbol: String {
        switch self {
        case .off: "moon"
        case .allowed: "checkmark.circle"
        case .paid: "eurosign.circle"
        case .forbidden: "minus.circle"
        case .unknown: "questionmark.circle"
        }
    }

    var tint: Color {
        switch self {
        case .off: SbuTheme.inkMuted
        case .allowed: SbuTheme.success
        case .paid, .unknown: SbuTheme.warning
        case .forbidden: SbuTheme.danger
        }
    }
}
