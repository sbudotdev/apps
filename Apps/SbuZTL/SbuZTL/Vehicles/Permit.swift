import Foundation

/// A permit the user declares they hold, for one vehicle and one zone. The app can't check it.
nonisolated struct Permit: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var vehicleID: Vehicle.ID
    var zoneID: Zone.ID
}
