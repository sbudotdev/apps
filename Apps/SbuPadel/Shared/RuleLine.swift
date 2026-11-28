import SbuKit
import SwiftUI

/// The line under the court while the match is played: the rule at 40 all, or Tie-break.
struct RuleLine: View {
    let score: MatchScore

    var body: some View {
        // The rule at 40 all does not count in a tie-break.
        Text(score.isTiebreak ? "Tie-break" : score.deuceRule.name)
            .font(SbuTheme.footnote)
            .foregroundStyle(SbuTheme.inkMuted)
            .frame(maxWidth: .infinity)
    }
}
