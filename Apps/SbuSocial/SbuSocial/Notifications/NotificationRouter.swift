import Observation
import UserNotifications

/// A tap on a message notification opens its Account's Platform in the browser.
@Observable
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    nonisolated static let accountKey = "account"

    /// The Account to open, until Home opens it.
    var pending: UUID?

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard let id = (response.notification.request.content.userInfo[Self.accountKey] as? String).flatMap(UUID.init) else { return }
        await open(id)
    }

    private func open(_ id: UUID) {
        pending = id
    }
}
