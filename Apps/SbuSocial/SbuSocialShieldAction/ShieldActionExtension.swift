import DeviceActivity
import Foundation
import ManagedSettings
import UserNotifications

/// The Shield's buttons. "Chiudi" closes the app. On an Intenzione's Shield, the second button
/// counts an opening and lifts the Shield for the Intenzione's minutes; a notification says so.
final class ShieldActionExtension: ShieldActionDelegate {
    private let defaults = UserDefaults(suiteName: "group.dev.sbu.social") ?? .standard

    override func handle(action: ShieldAction, for application: ApplicationToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        guard action == .secondaryButtonPressed else {
            completionHandler(.close)
            return
        }
        let now = Date.now
        var opened: Intention?
        let settings = ShieldSettings.update(in: defaults) { settings in
            // Only an Intenzione's Shield has the second button.
            guard case .intention(let intention) = settings.kind(for: application, now: now),
                  let index = settings.intentions.firstIndex(where: { $0.id == intention.id }) else { return }
            settings.intentions[index].open(now: now)
            opened = settings.intentions[index]
        }
        guard let opened, let end = opened.unlockedUntil else {
            completionHandler(.close)
            return
        }
        settings.apply(to: ManagedSettingsStore(named: ShieldSettings.storeName), in: defaults, now: now)
        // The Shield's return is the start of a one-off schedule: see `oneOff(from:to:)`.
        try? DeviceActivityCenter().startMonitoring(ShieldSettings.relockActivity(for: opened.id),
                                                    during: .oneOff(from: end, to: end.addingTimeInterval(15 * 60)))

        let length = Duration.seconds(opened.minutes * 60).formatted(.units(allowed: [.minutes], width: .wide))
        let content = UNMutableNotificationContent()
        content.title = opened.name.map { String(localized: "\($0) aperta per \(length)") } ?? String(localized: "App aperta per \(length)")
        content.body = String(localized: "Poi lo Schermo torna da solo.")
        let request = UNNotificationRequest(identifier: "open-\(opened.id.uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { _ in
            // ponytail: whether `.none` leaves you in the app without reopening it is unverified,
            // try `.defer` on a device if it does not.
            completionHandler(.none)
        }
    }

    override func handle(action: ShieldAction, for category: ActivityCategoryToken, completionHandler: @escaping (ShieldActionResponse) -> Void) {
        completionHandler(.close)
    }
}
