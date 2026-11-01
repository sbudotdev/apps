import Foundation
import Observation

/// Vehicles, permits, places and preferences, saved as one file in Application Support.
@Observable
final class AppStore {
    var state: PersistedState {
        didSet { save() }
    }

    private let url: URL?

    /// - Parameter url: `nil` keeps everything in memory, for previews and tests.
    init(url: URL? = AppStore.defaultURL, state: PersistedState? = nil) {
        self.url = url
        if let state {
            self.state = state
        } else if let url, let data = try? Data(contentsOf: url), let saved = try? JSONDecoder().decode(PersistedState.self, from: data) {
            self.state = saved
        } else {
            self.state = PersistedState()
        }
    }

    nonisolated static var defaultURL: URL? {
        try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("ztl.json")
    }

    /// Without a vehicle every rule answers "non lo so", and the route keeps out of every zone.
    var vehicle: Vehicle {
        state.vehicles.first { $0.id == state.selectedVehicleID } ?? state.vehicles.first
            ?? Vehicle(nickname: "", kind: .car, fuel: .petrol, euro: nil)
    }

    var hasVehicle: Bool { !state.vehicles.isEmpty }

    func save(_ vehicle: Vehicle) {
        if let index = state.vehicles.firstIndex(where: { $0.id == vehicle.id }) {
            state.vehicles[index] = vehicle
        } else {
            state.vehicles.append(vehicle)
        }
        state.selectedVehicleID = vehicle.id
    }

    func delete(_ vehicle: Vehicle) {
        state.vehicles.removeAll { $0.id == vehicle.id }
        state.permits.removeAll { $0.vehicleID == vehicle.id }
        if state.selectedVehicleID == vehicle.id { state.selectedVehicleID = state.vehicles.first?.id }
    }

    func remember(_ place: Place) {
        state.recents.removeAll { $0.id == place.id }
        state.recents.insert(place, at: 0)
        state.recents = Array(state.recents.prefix(10))
    }

    func isFavorite(_ place: Place) -> Bool {
        state.favorites.contains { $0.id == place.id }
    }

    func toggleFavorite(_ place: Place) {
        if isFavorite(place) {
            state.favorites.removeAll { $0.id == place.id }
        } else {
            state.favorites.append(place)
        }
    }

    private func save() {
        guard let url else { return }
        do {
            try JSONEncoder().encode(state).write(to: url, options: .atomic)
        } catch {
            assertionFailure("Saving failed: \(error)")
        }
    }
}
