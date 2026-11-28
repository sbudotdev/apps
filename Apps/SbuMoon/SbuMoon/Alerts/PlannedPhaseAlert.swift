import Foundation

/// One notification to hand to iOS: the phase, when it happens, and when to say so.
nonisolated struct PlannedPhaseAlert: Equatable, Sendable {
    var phase: PrincipalPhase
    var eventDate: Date
    /// When the notification arrives: the chosen time on the day of the phase.
    var fireDate: Date

    /// Stable for the same phase instant, so a new plan replaces rather than duplicates.
    var identifier: String {
        "phase-\(phase.storageKey)-\(Int(eventDate.timeIntervalSince1970))"
    }

    /// An alert of an older plan, to take back. Never another app's notification: inside Sbu the
    /// notification center is shared with Subscriptions (ADR-0027).
    static func isStale(_ identifier: String, keeping planned: Set<String>) -> Bool {
        identifier.hasPrefix("phase-") && !planned.contains(identifier)
    }
}
