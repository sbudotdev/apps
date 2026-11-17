import SbuKit
import SwiftUI

/// The game inside the standard Sbu shell.
struct RootView: View {
    #if DEBUG
    @State private var store = GameStore(now: { ForcedToday.date ?? .now })
    #else
    @State private var store = GameStore()
    #endif

    var body: some View {
        SbuAppShell("Sbu Squares", slug: "squares", accent: .squares, appIcon: Image(.appIconArtwork)) {
            MainView(store: store)
        } settings: {
            RecordSection(store: store)
        }
        #if DEBUG
        .transformEnvironment(\.sbuSeason) { season in
            if let today = ForcedToday.date { season = SbuSeason.active(on: today) }
        }
        #endif
    }
}

#Preview("Light") {
    RootView()
}

#Preview("Dark") {
    RootView()
        .preferredColorScheme(.dark)
}
