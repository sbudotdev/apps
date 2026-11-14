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

nonisolated extension PersistedState {
    /// A field missing from an older file takes its default, so an update never empties what you saved.
    init(from decoder: any Decoder) throws {
        self.init()
        let c = try decoder.container(keyedBy: CodingKeys.self)
        vehicles = try c.decodeIfPresent([Vehicle].self, forKey: .vehicles) ?? vehicles
        selectedVehicleID = try c.decodeIfPresent(Vehicle.ID.self, forKey: .selectedVehicleID)
        permits = try c.decodeIfPresent([Permit].self, forKey: .permits) ?? permits
        favorites = try c.decodeIfPresent([Place].self, forKey: .favorites) ?? favorites
        recents = try c.decodeIfPresent([Place].self, forKey: .recents) ?? recents
        hasFinishedIntro = try c.decodeIfPresent(Bool.self, forKey: .hasFinishedIntro) ?? hasFinishedIntro
        avoidsPaidZones = try c.decodeIfPresent(Bool.self, forKey: .avoidsPaidZones) ?? avoidsPaidZones
        keepsNorthUp = try c.decodeIfPresent(Bool.self, forKey: .keepsNorthUp) ?? keepsNorthUp
        shows3D = try c.decodeIfPresent(Bool.self, forKey: .shows3D) ?? shows3D
        showsParking = try c.decodeIfPresent(Bool.self, forKey: .showsParking) ?? showsParking
        speaks = try c.decodeIfPresent(Bool.self, forKey: .speaks) ?? speaks
    }
}
