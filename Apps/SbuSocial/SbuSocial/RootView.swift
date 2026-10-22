import SbuKit
import SwiftUI

/// The app inside `SbuTabShell`: Sonno, Statistiche, Home, Blocco, then Impostazioni (ADR-0017).
struct RootView: View {
    @Environment(OptionStore.self) private var options
    @Environment(MessageNotifications.self) private var notifications
    @Environment(NotificationRouter.self) private var router
    @State private var tab = AppTab.home

    var body: some View {
        SbuTabShell("Sbu Social", slug: "social", accent: .social, appIcon: Image(.appIconArtwork),
                    selection: $tab, settingsTab: AppTab.settings) {
            SbuTab("Sonno", systemImage: "moon.zzz", value: AppTab.sleep) {
                SleepView()
            }
            SbuTab("Statistiche", systemImage: "chart.bar", value: AppTab.stats) {
                StatsView()
            }
            SbuTab("Home", systemImage: "house", value: AppTab.home) {
                HomeView()
            }
            SbuTab("Blocco", systemImage: "shield", value: AppTab.block) {
                BlockView()
            }
        } settings: {
            LaunchSection(options: options)
            NotificationSection(notifications: notifications)
            ForEach(Platform.allCases.filter { !$0.rules.options.isEmpty }) { platform in
                FilterSection(platform: platform, options: options)
            }
        }
        // A message notification opens its Platform from Home.
        .onChange(of: router.pending) {
            if router.pending != nil { tab = .home }
        }
    }
}

#Preview("Light") {
    RootView()
        .environment(AccountStore(defaults: UserDefaults(suiteName: "preview")!))
        .environment(WebViewPool(options: OptionStore(defaults: UserDefaults(suiteName: "preview")!)))
        .environment(OptionStore(defaults: UserDefaults(suiteName: "preview")!))
        .environment(UsageLog(defaults: UserDefaults(suiteName: "preview")!))
        .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!))
        .environment(MessageNotifications(defaults: UserDefaults(suiteName: "preview")!))
        .environment(NotificationRouter())
}

#Preview("Dark") {
    RootView()
        .environment(AccountStore(defaults: UserDefaults(suiteName: "preview")!))
        .environment(WebViewPool(options: OptionStore(defaults: UserDefaults(suiteName: "preview")!)))
        .environment(OptionStore(defaults: UserDefaults(suiteName: "preview")!))
        .environment(UsageLog(defaults: UserDefaults(suiteName: "preview")!))
        .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!))
        .environment(MessageNotifications(defaults: UserDefaults(suiteName: "preview")!))
        .environment(NotificationRouter())
        .preferredColorScheme(.dark)
}
