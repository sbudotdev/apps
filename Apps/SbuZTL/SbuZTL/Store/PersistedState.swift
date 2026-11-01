import Foundation

/// What the app remembers, on this device only.
nonisolated struct PersistedState: Codable, Sendable {
    var vehicles: [Vehicle] = []
    var selectedVehicleID: Vehicle.ID?
    var permits: [Permit] = []
    var favorites: [Place] = []
    var recents: [Place] = []
    var hasFinishedIntro = false
    var avoidsPaidZones = true
    var keepsNorthUp = false
    var shows3D = true
    var showsParking = false
    var speaks = true
}
