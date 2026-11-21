import CoreGraphics
import Foundation

/// Quanto spesso passano da soli i visitatori (Impostazioni → Visitatori, SBU-187): moltiplica le attese.
/// Dal menu passano sempre, subito.
nonisolated enum VisitFrequency: String, CaseIterable, Sendable {
    case often, sometimes, rarely

    /// La chiave in UserDefaults; all'inizio "ogni tanto", cioè le attese di `Tuning`.
    static let key = "visitFrequency"

    static var saved: VisitFrequency {
        UserDefaults.standard.string(forKey: key).flatMap(VisitFrequency.init(rawValue:)) ?? .sometimes
    }

    private var factor: CGFloat {
        switch self {
        case .often: 0.5
        case .sometimes: 1
        case .rarely: 2
        }
    }

    /// L'attesa `range` con questa frequenza.
    func scaled(_ range: ClosedRange<CGFloat>) -> ClosedRange<CGFloat> {
        range.lowerBound * factor...range.upperBound * factor
    }
}
