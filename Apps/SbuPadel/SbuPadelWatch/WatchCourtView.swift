import SbuKit
import SwiftUI

/// Two halves of the screen, Noi and Loro: a tap on a half is a point to that pair.
struct WatchCourtView: View {
    let board: Scoreboard

    var body: some View {
        let score = board.score
        VStack(spacing: SbuTheme.space1) {
            HStack(spacing: SbuTheme.space1) {
                ForEach(Side.allCases, id: \.self) { side in
                    SideButton(side: side, score: score, figureSize: SbuTheme.figureWidget) {
                        board.point(to: side)
                    }
                }
            }
            ResultLine(score: score)
        }
        .ignoresSafeArea(edges: .bottom)
        .background(SbuTheme.paper)
    }
}
