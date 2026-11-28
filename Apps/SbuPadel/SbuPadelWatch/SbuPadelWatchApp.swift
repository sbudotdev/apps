import SbuKit
import SwiftUI

@main
struct SbuPadelWatchApp: App {
    @State private var board = Scoreboard()

    var body: some Scene {
        WindowGroup {
            WatchRootView(board: board)
                .tint(SbuTheme.ink)
                // No shell on the watch: the accent of the full stop comes from here.
                .environment(\.sbuAccent, .steps)
        }
    }
}
