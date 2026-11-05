import SbuKit
import SwiftUI

/// The app inside `SbuTabShell`: Home, then Impostazioni.
struct RootView: View {
    @State private var tab = AppTab.home

    var body: some View {
        SbuTabShell("Sbu Social", slug: "social", accent: .social, appIcon: Image(.appIconArtwork),
                    selection: $tab, settingsTab: AppTab.settings) {
            SbuTab("Home", systemImage: "house", value: AppTab.home) {
                HomeView()
            }
        } settings: {
        }
    }
}

#Preview("Light") {
    RootView()
        .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!))
}

#Preview("Dark") {
    RootView()
        .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!))
        .preferredColorScheme(.dark)
}
