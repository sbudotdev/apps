import SbuKit
import SwiftUI

extension View {
    /// A different haptic for a point, a game, and a set or the match.
    func matchHaptics(_ board: Scoreboard) -> some View {
        sbuHaptic(.tick, trigger: board.pointTaps)
            .sbuHaptic(.dot, trigger: board.gameTaps)
            .sbuHaptic(.closure, trigger: board.setTaps)
    }
}
