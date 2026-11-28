import SbuKit
import SwiftUI

/// The app inside the standard Sbu shell.
struct RootView: View {
    let board: Scoreboard

    var body: some View {
        // shortcut: borrows Sbu Steps' accent, as there is no accent-padel token yet; add one with the real icon.
        SbuAppShell("Sbu Padel", slug: "padel", accent: .steps, appIcon: Image(.appIconArtwork)) {
            MatchView(board: board)
        } settings: {
            EmptyView()
        }
    }
}

#Preview("Light") {
    RootView(board: Scoreboard(defaults: UserDefaults(suiteName: "preview")!))
}

#Preview("Dark") {
    RootView(board: Scoreboard(defaults: UserDefaults(suiteName: "preview")!))
        .preferredColorScheme(.dark)
}
