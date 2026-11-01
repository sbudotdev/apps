import Foundation

/// A zone's timetable and what it means for a vehicle while in force.
nonisolated struct ZoneRule: Sendable {
    let schedule: Schedule
    let car: Access
    let carReason: LocalizedStringResource
    let twoWheels: Access
    let twoWheelsReason: LocalizedStringResource
    /// Car fuels the source doesn't settle: they answer `.unknown`.
    var unverifiedFuels: Set<Fuel> = []
    let offReason: LocalizedStringResource
    let source: RuleSource
}
