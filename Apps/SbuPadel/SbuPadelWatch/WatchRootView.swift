import SwiftUI

/// The court on the first page, the controls one swipe down so a sweaty hand cannot hit them.
struct WatchRootView: View {
    let board: Scoreboard

    var body: some View {
        TabView {
            WatchCourtView(board: board)
            WatchControlsView(board: board)
        }
        .tabViewStyle(.verticalPage)
        .matchHaptics(board)
    }
}

#Preview("Light") {
    WatchRootView(board: Scoreboard(defaults: UserDefaults(suiteName: "preview")!))
        .environment(\.sbuAccent, .steps)
}

#Preview("Dark") {
    WatchRootView(board: Scoreboard(defaults: UserDefaults(suiteName: "preview")!))
        .environment(\.sbuAccent, .steps)
        .preferredColorScheme(.dark)
}
