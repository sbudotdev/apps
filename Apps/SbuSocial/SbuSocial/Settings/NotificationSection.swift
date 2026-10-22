import SwiftUI
import UserNotifications

/// Impostazioni: notifications of new messages, off until you turn them on, as each one costs a
/// look at your messages page in the background.
struct NotificationSection: View {
    let notifications: MessageNotifications

    var body: some View {
        Section {
            ForEach(MessageNotifications.available) { platform in
                Toggle(isOn: Binding {
                    notifications.isOn(platform)
                } set: { isOn in
                    notifications.set(platform, to: isOn)
                    InboxCheck.schedule(notifications)
                    if isOn { Task { await askPermission(for: platform) } }
                }) {
                    Text("Messaggi di \(platform.name)")
                }
            }
        } header: {
            Text("Notifiche")
        } footer: {
            Text("Sbu Social guarda i tuoi messaggi quando iOS glielo lascia fare: le notifiche possono arrivare in ritardo. Instagram potrebbe chiederti di confermare che sei tu.")
        }
    }

    /// Asked when you turn the first one on; without it the switch goes back off.
    private func askPermission(for platform: Platform) async {
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        if !granted {
            notifications.set(platform, to: false)
            InboxCheck.schedule(notifications)
        }
    }
}

#Preview("Light") {
    Form {
        NotificationSection(notifications: MessageNotifications(defaults: UserDefaults(suiteName: "preview")!))
    }
}

#Preview("Dark") {
    Form {
        NotificationSection(notifications: MessageNotifications(defaults: UserDefaults(suiteName: "preview")!))
    }
    .preferredColorScheme(.dark)
}
