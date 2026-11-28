import Foundation

extension DeuceRule {
    /// The rule as it is shown once the match has started.
    var name: LocalizedStringResource { self == .goldenPoint ? "Punto d'oro" : "Vantaggi" }
}
