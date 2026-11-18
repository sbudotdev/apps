import CoreLocation
import XCTest

/// Drives the demo video (SBU-131): a drive simulated with fixes that carry a speed, from a stop
/// up to 50 km/h on the central figure, then on the Parabrezza.
/// Not a check: it runs only in the Snapshots scheme, while `simctl io recordVideo` records. The first
/// run on a simulator allows location in the alert: record the second.
final class VideoTests: XCTestCase {
    private let start = Date()
    private var second = 0.0
    private var metersNorth = 0.0

    /// One fix a second, going north from Milan at `speed` m/s.
    @MainActor
    private func drive(at speed: Double) {
        let coordinate = CLLocationCoordinate2D(latitude: 45.4642 + metersNorth / 111_000, longitude: 9.19)
        let location = CLLocation(
            coordinate: coordinate, altitude: 120, horizontalAccuracy: 5, verticalAccuracy: 5,
            course: 0, courseAccuracy: 5, speed: speed, speedAccuracy: 0.5,
            timestamp: start.addingTimeInterval(second)
        )
        XCUIDevice.shared.location = XCUILocation(location: location)
        metersNorth += speed
        second += 1
        Thread.sleep(forTimeInterval: 1)
    }

    @MainActor
    func testVideo() {
        // Standing still before the launch: the simulator keeps the last fix of a run before.
        drive(at: 0)
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(it)", "-AppleLocale", "it_IT", "-trip", ""]
        app.launch()
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons
            .matching(NSPredicate(format: "label BEGINSWITH 'Consenti quando' OR label BEGINSWITH 'Consenti mentre'")).firstMatch
        if allow.waitForExistence(timeout: 2) {
            allow.tap()
        }

        drive(at: 0)
        // Up to 13.9 m/s, 50 km/h, then steady.
        for step in 1...8 {
            drive(at: 13.9 * Double(step) / 8)
        }
        for _ in 0..<3 {
            drive(at: 13.9)
        }

        app.buttons["Parabrezza"].tap()
        for speed in [13.9, 13.9, 12.5, 11.1, 11.1] {
            drive(at: speed)
        }
    }
}
