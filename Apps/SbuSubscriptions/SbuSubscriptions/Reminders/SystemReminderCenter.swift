import Foundation
import UserNotifications

/// Hands reminders to iOS. The only notifications the app ever sends, all local.
struct SystemReminderCenter: ReminderCenter {
    func access() async -> NotificationAccess {
        switch await UNUserNotificationCenter.current().notificationSettings().authorizationStatus {
        case .notDetermined: .notDetermined
        case .denied: .denied
        default: .allowed
        }
    }

    func requestAccess() async -> NotificationAccess {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        return await access()
    }

    func replace(with reminders: [PlannedReminder]) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let requests = reminders.map { reminder in
            let content = UNMutableNotificationContent()
            content.title = reminder.name
            content.body = ReminderText.body(for: reminder)
            content.sound = .default
            let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate)
            return UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false))
        }
        let planned = Set(requests.map(\.identifier))
        // Only its own old reminders go, never another tool's inside Sbu (ADR-0027). Taken back and added in the
        // same callback, so a plan made right after never loses a reminder to this one's late removal.
        center.getPendingNotificationRequests { pending in
            let stale = pending.map(\.identifier).filter { PlannedReminder.isStale($0, keeping: planned) }
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: stale)
            // A reminder iOS refuses is skipped; the next save or launch plans it again.
            requests.forEach { center.add($0) }
        }
    }

    func sendTest() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Sbu Subscriptions")
        content.body = String(localized: "Così arrivano i promemoria prima di ogni rinnovo.")
        content.sound = .default
        // Delivered now, never pending: a reschedule never has to keep it.
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "test", content: content, trigger: nil))
    }
}
