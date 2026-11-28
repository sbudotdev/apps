import Testing
@testable import SbuSubscriptions

/// Inside Sbu the notification center is shared with Moon: Subscriptions clears only its own old reminders.
struct ReminderStaleTests {
    @Test(arguments: [
        ("subscription-ABC-100", true),
        ("subscription-ABC-200", false),
        ("phase-full-100", false),
        ("test", false),
    ])
    func onlyItsOwnRemindersOutsideTheNewPlanAreCleared(identifier: String, stale: Bool) {
        #expect(PlannedReminder.isStale(identifier, keeping: ["subscription-ABC-200"]) == stale)
    }
}
