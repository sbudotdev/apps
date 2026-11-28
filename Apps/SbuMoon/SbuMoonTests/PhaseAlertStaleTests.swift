import Testing
@testable import SbuMoon

/// Inside Sbu the notification center is shared with Subscriptions: Moon clears only its own old alerts.
nonisolated struct PhaseAlertStaleTests {
    @Test(arguments: [
        ("phase-full-100", true),
        ("phase-new-200", false),
        ("subscription-ABC-100", false),
        ("test", false),
    ])
    func onlyItsOwnAlertsOutsideTheNewPlanAreCleared(identifier: String, stale: Bool) {
        #expect(PlannedPhaseAlert.isStale(identifier, keeping: ["phase-new-200"]) == stale)
    }
}
