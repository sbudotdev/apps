import Foundation

/// Where the driver is on the route.
nonisolated struct GuidanceState: Sendable, Equatable {
    var stepIndex = 0
    var metresToManeuver = 0.0
    var remainingMetres = 0.0
    var remainingSeconds = 0.0
    var limit = 0
    var isOffRoute = false
    var hasArrived = false
}
