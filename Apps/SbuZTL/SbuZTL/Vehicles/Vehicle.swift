import Foundation

/// A vehicle, filled in by hand: no lookup service, nothing leaves the phone.
nonisolated struct Vehicle: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var nickname: String
    var kind: VehicleKind
    var fuel: Fuel
    /// `nil` for an electric vehicle, which has no class.
    var euro: EuroClass?
}
