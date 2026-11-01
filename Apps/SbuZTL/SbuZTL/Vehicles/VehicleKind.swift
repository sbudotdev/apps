import Foundation

nonisolated enum VehicleKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case car
    case motorcycle
    case moped

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .car: "Auto"
        case .motorcycle: "Moto"
        case .moped: "Ciclomotore"
        }
    }

    var symbol: String {
        switch self {
        case .car: "car.fill"
        case .motorcycle: "motorcycle.fill"
        case .moped: "scooter"
        }
    }
}
