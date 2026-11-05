import SwiftUI

@main
struct SbuSocialApp: App {
    @State private var shield = ShieldModel(defaults: LaunchMode.current.defaults, isDemo: LaunchMode.current != .user)
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(shield)
                .onChange(of: scenePhase, initial: true) {
                    if scenePhase == .active { shield.refresh() }
                }
                // With the app open, the Shield changes on time even if iOS is late.
                .task(id: shield.nextChange()) {
                    guard let next = shield.nextChange() else { return }
                    // One second past the moment, so the refresh never lands just before it.
                    try? await Task.sleep(for: .seconds(max(next.timeIntervalSinceNow, 0) + 1))
                    shield.refresh()
                }
        }
    }
}
