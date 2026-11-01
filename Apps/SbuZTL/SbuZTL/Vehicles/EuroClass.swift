import Foundation

/// The emission class on the registration document.
nonisolated enum EuroClass: String, Codable, CaseIterable, Sendable, Identifiable {
    case euro0, euro1, euro2, euro3, euro4, euro5, euro6abc, euro6d

    var id: String { rawValue }

    /// Euro classes read the same in every language.
    var title: String {
        switch self {
        case .euro0: "Euro 0"
        case .euro1: "Euro 1"
        case .euro2: "Euro 2"
        case .euro3: "Euro 3"
        case .euro4: "Euro 4"
        case .euro5: "Euro 5"
        case .euro6abc: "Euro 6 A-B-C"
        case .euro6d: "Euro 6 D"
        }
    }
}
