import SbuKit
import SwiftUI

/// The app inside `SbuTabShell`: Home, Sessioni, then Impostazioni (ADR-0021).
struct RootView: View {
    @State private var tab = AppTab.home

    var body: some View {
        SbuTabShell("Sbu Social", slug: "social", accent: .social, appIcon: Image(.appIconArtwork),
                    selection: $tab, settingsTab: AppTab.settings) {
            SbuTab("Home", systemImage: "house", value: AppTab.home) {
                HomeView()
            }
            SbuTab("Sessioni", systemImage: "calendar", value: AppTab.sessions) {
                SessionsView()
            }
        } settings: {
        }
    }
}

#Preview("Light") {
    RootView()
        .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
}

#Preview("Dark") {
    RootView()
        .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
        .preferredColorScheme(.dark)
}
