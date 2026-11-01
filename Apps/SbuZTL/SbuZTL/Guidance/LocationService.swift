import CoreLocation
import Observation

/// The phone's position. Asks for permission only when something needs it.
@Observable
final class LocationService {
    private(set) var fix: LocationFix?
    private(set) var isDenied = false
    private let manager = CLLocationManager()
    private let fixed: LocationFix?
    private var feed: Task<Void, Never>?

    init(fixed: LocationFix? = nil) {
        self.fixed = fixed
        fix = fixed
    }

    /// Starts listening, asking the first time.
    func start() {
        guard fixed == nil, feed == nil else { return }
        if manager.authorizationStatus == .notDetermined { manager.requestWhenInUseAuthorization() }
        feed = Task { [weak self] in
            do {
                for try await update in CLLocationUpdate.liveUpdates(.automotiveNavigation) {
                    guard let self else { return }
                    self.isDenied = [.denied, .restricted].contains(self.manager.authorizationStatus)
                    if let location = update.location {
                        self.fix = LocationFix(point: Point(location.coordinate), accuracy: location.horizontalAccuracy,
                                               speed: max(location.speed, 0), date: location.timestamp)
                    }
                }
            } catch {
                self?.isDenied = true
            }
        }
    }

    /// Waits a moment for the first position. `nil` means the app must say it can't find you.
    func currentFix(timeout: Duration = .seconds(8)) async -> LocationFix? {
        start()
        let clock = ContinuousClock()
        let end = clock.now.advanced(by: timeout)
        while fix == nil, clock.now < end, !isDenied, !Task.isCancelled {
            try? await clock.sleep(for: .milliseconds(200))
        }
        return fix
    }
}
