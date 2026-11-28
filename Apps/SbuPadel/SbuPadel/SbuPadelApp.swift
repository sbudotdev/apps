import SwiftUI

@main
struct SbuPadelApp: App {
    @State private var board = Scoreboard()

    var body: some Scene {
        WindowGroup {
            RootView(board: board)
        }
    }
}
