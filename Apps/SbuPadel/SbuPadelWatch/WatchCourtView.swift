import SbuKit
import SwiftUI

/// The sets on top, then two halves of the screen, Noi and Loro: a tap on a half is a point to
/// that pair. Undo is the small button in the corner, away from the halves, as in the other
/// scorers; once the match is over the halves give way to the result.
struct WatchCourtView: View {
    let board: Scoreboard

    var body: some View {
        let score = board.score
        VStack(spacing: SbuTheme.space1) {
            SetTable(score: score, digitFont: SbuTheme.headline.monospacedDigit())
                .font(SbuTheme.footnote)
            if score.winner == nil {
                HStack(spacing: SbuTheme.space1) {
                    ForEach(Side.allCases, id: \.self) { side in
                        SideButton(side: side, score: score, figureSize: SbuTheme.figureWidget) {
                            board.point(to: side)
                        }
                    }
                }
            } else {
                MatchResult(score: score, figureSize: SbuTheme.figureWidget)
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .background(SbuTheme.paper)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Annulla punto", systemImage: "arrow.uturn.backward", action: board.undo)
                    .foregroundStyle(SbuTheme.paper)
                    .disabled(board.match.hasStarted == false)
            }
        }
    }
}

#Preview("Light") {
    NavigationStack {
        WatchCourtView(board: Scoreboard(defaults: UserDefaults(suiteName: "preview")!))
    }
    .environment(\.sbuAccent, .steps)
}

#Preview("Dark") {
    NavigationStack {
        WatchCourtView(board: Scoreboard(defaults: UserDefaults(suiteName: "preview")!))
    }
    .environment(\.sbuAccent, .steps)
    .preferredColorScheme(.dark)
}
