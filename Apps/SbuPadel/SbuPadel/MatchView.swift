import SbuKit
import SwiftUI

/// The one screen: the court in two halves, then undo, a new match and the rules.
struct MatchView: View {
    let board: Scoreboard

    var body: some View {
        let score = board.score
        VStack(spacing: SbuTheme.space4) {
            SbuScreenTitle("Padel", cartiglio: "SBU · PADEL")
            HStack(spacing: SbuTheme.space2) {
                ForEach(Side.allCases, id: \.self) { side in
                    SideButton(side: side, score: score, figureSize: SbuTheme.figureHeroMin) {
                        board.point(to: side)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            ResultLine(score: score)
            RulesPickers(board: board)
                .pickerStyle(.segmented)
            HStack(spacing: SbuTheme.space2) {
                SbuButton("Annulla punto", kind: .secondary, action: board.undo)
                    .disabled(board.match.hasStarted == false)
                SbuButton("Nuova partita", kind: .destructive, confirmationTitle: "Il punteggio di questa partita si cancella.", action: board.newMatch)
                    .disabled(board.match.hasStarted == false)
            }
        }
        .padding(SbuTheme.space4)
        .background(SbuTheme.paper)
        .matchHaptics(board)
    }
}

#Preview("Light") {
    MatchView(board: Scoreboard(defaults: UserDefaults(suiteName: "preview")!))
        .environment(\.sbuAccent, .steps)
}

#Preview("Dark") {
    MatchView(board: Scoreboard(defaults: UserDefaults(suiteName: "preview")!))
        .environment(\.sbuAccent, .steps)
        .preferredColorScheme(.dark)
}
