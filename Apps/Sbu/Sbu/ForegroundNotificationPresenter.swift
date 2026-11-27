import UserNotifications

/// Shows a tool's notification (a moon phase, a renewal) as a banner even while Sbu is open.
/// The same as Moon's and Subscriptions' own presenter: the center takes one delegate per app.
final class ForegroundNotificationPresenter: NSObject, UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
