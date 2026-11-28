import SbuKit
import SwiftUI

/// One line under the court: the result once the match is over, or Tie-break while one is played.
struct ResultLine: View {
    let score: MatchScore

    var body: some View {
        Group {
            if let winner = score.winner {
                Text(winner == .us ? "Partita vinta" : "Partita persa")
                    .font(SbuTheme.headline)
                    .foregroundStyle(SbuTheme.ink)
            } else if score.isTiebreak {
                Text("Tie-break")
                    .font(SbuTheme.footnote)
                    .foregroundStyle(SbuTheme.inkMuted)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
