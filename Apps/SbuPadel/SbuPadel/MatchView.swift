import SbuKit
import SwiftUI

/// The one screen: the sets, the court in two halves, then the rules before the first point, undo
/// and a new match. The end of the match closes with Vinta or Persa, then shows the result.
struct MatchView: View {
    let board: Scoreboard
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var isClosing = false
    @ScaledMetric(relativeTo: .title2) private var digitSize = SbuTheme.statSmallSize

    /// Side by side, or one under the other at the accessibility sizes so no word breaks.
    private var buttonsLayout: AnyLayout {
        dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: SbuTheme.space2))
            : AnyLayout(HStackLayout(spacing: SbuTheme.space2))
    }

    var body: some View {
        // At the accessibility sizes the screen scrolls, so no button is cut.
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                ScrollView { content }
            } else {
                content
            }
        }
        .background(SbuTheme.paper)
        .matchHaptics(board)
        // The haptic is already the set's, from matchHaptics.
        .onChange(of: board.score.winner) { _, winner in
            if winner != nil { isClosing = true }
        }
    }

    /// The halves, or the result once the match is over: the rest of the screen, or half of it
    /// when the screen scrolls.
    @ViewBuilder
    private func courtZone(_ score: MatchScore) -> some View {
        let court = Group {
            if score.winner == nil {
                HStack(spacing: SbuTheme.space2) {
                    ForEach(Side.allCases, id: \.self) { side in
                        SideButton(side: side, score: score, figureSize: SbuTheme.figureHeroMin) {
                            board.point(to: side)
                        }
                    }
                }
            } else {
                MatchResult(score: score, figureSize: SbuTheme.figureHeroMin)
            }
        }
        if dynamicTypeSize.isAccessibilitySize {
            court.containerRelativeFrame(.vertical) { length, _ in length / 2 }
        } else {
            court.frame(maxHeight: .infinity)
        }
    }

    private var content: some View {
        let score = board.score
        return VStack(spacing: SbuTheme.space4) {
            SbuScreenTitle("Padel", cartiglio: "SBU · PADEL")
            SetTable(score: score, digitFont: SbuTheme.smallNumberFont(size: digitSize))
                .padding(SbuTheme.space3)
                .background(SbuTheme.surfaceRaised, in: .rect(cornerRadius: SbuTheme.radiusCard))
                .overlay(RoundedRectangle(cornerRadius: SbuTheme.radiusCard).strokeBorder(SbuTheme.line))
            courtZone(score)
                .sbuClosure($isClosing, word: score.winner == .them ? "Persa" : "Vinta", playsHaptic: false)
            if board.match.hasStarted == false {
                RulesPickers(board: board)
            } else if score.winner == nil {
                RuleLine(score: score)
            }
            buttonsLayout {
                SbuButton("Annulla punto", kind: .secondary, action: board.undo)
                    .disabled(board.match.hasStarted == false)
                SbuButton("Nuova partita", kind: .destructive, confirmationTitle: "Cancellare il punteggio di questa partita?", action: board.newMatch)
                    .disabled(board.match.hasStarted == false)
            }
        }
        .padding(SbuTheme.space4)
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
