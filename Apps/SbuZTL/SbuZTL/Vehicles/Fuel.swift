import Foundation

nonisolated enum Fuel: String, Codable, CaseIterable, Sendable, Identifiable {
    case petrol
    case diesel
    case gas
    case hybrid
    case electric

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .petrol: "Benzina"
        case .diesel: "Gasolio"
        case .gas: "GPL o metano"
        case .hybrid: "Ibrida"
        case .electric: "Elettrica"
        }
    }
}
