import SwiftUI

/// The court on the first page, the controls one swipe down so a sweaty hand cannot hit them.
/// The workout runs while the match is played, and the match closes with Vinta or Persa.
struct WatchRootView: View {
    let board: Scoreboard
    let workout: MatchWorkout
    @State private var isClosing = false

    private var isPlaying: Bool { board.match.hasStarted && board.score.winner == nil }

    var body: some View {
        NavigationStack {
            TabView {
                WatchCourtView(board: board)
                    .sbuClosure($isClosing, word: board.score.winner == .them ? "Persa" : "Vinta", playsHaptic: false)
                WatchControlsView(board: board, workout: workout)
            }
            .tabViewStyle(.verticalPage)
        }
        .matchHaptics(board)
        .onChange(of: board.score.winner) { _, winner in
            if winner != nil { isClosing = true }
        }
        .task(id: isPlaying) {
            // shortcut: screenshots and UI runs skip the Salute prompt; drop when they can answer it.
            guard CommandLine.arguments.contains("-noWorkout") == false else { return }
            if isPlaying { await workout.start() } else { await workout.end() }
        }
    }
}

#Preview("Light") {
    WatchRootView(board: Scoreboard(defaults: UserDefaults(suiteName: "preview")!), workout: MatchWorkout())
        .environment(\.sbuAccent, .steps)
}

#Preview("Dark") {
    WatchRootView(board: Scoreboard(defaults: UserDefaults(suiteName: "preview")!), workout: MatchWorkout())
        .environment(\.sbuAccent, .steps)
        .preferredColorScheme(.dark)
}
