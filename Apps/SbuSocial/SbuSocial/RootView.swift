import SbuKit
import SwiftUI

/// The app inside `SbuTabShell`: Home, Sessioni, then Impostazioni (ADR-0021).
struct RootView: View {
    @Environment(ShieldModel.self) private var shield
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
            GoalSection(shield: shield)
            ProgressSection(shield: shield)
            AccessSection(shield: shield)
        }
        // First run: the app does nothing until Screen Time, an Intenzione and the allowed apps are set.
        .fullScreenCover(isPresented: .constant(!shield.settings.isSetUp)) {
            SetupView()
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
