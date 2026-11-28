import SubscriptionsTool
import SwiftUI
import UserNotifications

@main
struct SbuApp: App {
    /// Kept for the app's lifetime: the notification center holds its delegate weakly.
    private let notificationPresenter = ForegroundNotificationPresenter()

    init() {
        UNUserNotificationCenter.current().delegate = notificationPresenter
        SubscriptionsTool.registerIntentDependencies()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
