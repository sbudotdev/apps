import Foundation
import SwiftUI

@main
struct SbuPadelApp: App {
    @State private var board: Scoreboard

    init() {
        // UI tests start from an empty match.
        if CommandLine.arguments.contains("-resetMatch") { UserDefaults.standard.removeObject(forKey: "match") }
        _board = State(initialValue: Scoreboard())
    }

    var body: some Scene {
        WindowGroup {
            RootView(board: board)
        }
    }
}
