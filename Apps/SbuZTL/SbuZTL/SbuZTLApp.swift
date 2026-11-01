import SwiftUI

@main
struct SbuZTLApp: App {
    private let store: AppStore
    private let location: LocationService

    init() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-uiTesting") {
            let start = LocationFix(point: Point(45.5140, 9.2100), accuracy: 5, speed: 0, date: .now)
            let vehicles = arguments.contains("-withVehicle") ? [Vehicle(nickname: "Panda", kind: .car, fuel: .petrol, euro: .euro5)] : []
            store = AppStore(url: nil, state: PersistedState(vehicles: vehicles, hasFinishedIntro: arguments.contains("-withVehicle")))
            location = LocationService(fixed: start)
            return
        }
        #endif
        store = AppStore()
        location = LocationService()
    }

    var body: some Scene {
        WindowGroup {
            RootView(store: store, location: location)
        }
    }
}
