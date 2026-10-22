import AVFoundation
import SwiftUI
import UserNotifications

@main
struct SbuSocialApp: App {
    @State private var accounts = AccountStore()
    @State private var options: OptionStore
    @State private var pool: WebViewPool
    @State private var usage = UsageLog.isDemo ? UsageLog.demo() : UsageLog()
    @State private var shield = ShieldModel()
    @State private var notifications = MessageNotifications()
    @State private var router: NotificationRouter
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let options = OptionStore()
        _options = State(initialValue: options)
        _pool = State(initialValue: WebViewPool(options: options))
        // Set before launch ends, so a tap that launched the app still reaches it.
        let router = NotificationRouter()
        UNUserNotificationCenter.current().delegate = router
        _router = State(initialValue: router)
        // Videos play with the silent switch on and keep playing in the background, as in SocialLite.
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(accounts)
                .environment(pool)
                .environment(options)
                .environment(usage)
                .environment(shield)
                .environment(notifications)
                .environment(router)
                .task { await pool.prepare() }
                #if DEBUG
                // `-checkInbox` runs the message check at launch, without waiting for iOS.
                .task {
                    if CommandLine.arguments.contains("-checkInbox") { await InboxCheck.run() }
                }
                #endif
                .onChange(of: scenePhase, initial: true) {
                    if scenePhase == .active { shield.refresh() }
                    if scenePhase == .background { InboxCheck.schedule(notifications) }
                }
                // With the app open, the Shield comes back on time even if iOS is late.
                .task(id: [shield.postModeEnd, shield.focusEnd]) {
                    guard let end = [shield.postModeEnd, shield.focusEnd].compactMap(\.self).min() else { return }
                    try? await Task.sleep(for: .seconds(max(end.timeIntervalSinceNow, 0)))
                    shield.refresh()
                }
        }
        .backgroundTask(.appRefresh(InboxCheck.identifier)) {
            await InboxCheck.run()
        }
    }
}
