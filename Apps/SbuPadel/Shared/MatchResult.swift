import SbuKit
import SwiftUI

/// The court once the match is over: the sets won as the figure, then won or lost and the sets
/// as they are written.
struct MatchResult: View {
    let score: MatchScore
    let figureSize: CGFloat

    var body: some View {
        let sets = score.setsWon
        VStack(spacing: SbuTheme.space1) {
            Text(verbatim: "\(sets.us)-\(sets.them)")
                .font(.sbuFigure(size: figureSize))
                .foregroundStyle(SbuTheme.ink)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.4)
            Text(score.winner == .us ? "Partita vinta" : "Partita persa")
                .font(SbuTheme.headline)
                .foregroundStyle(SbuTheme.ink)
            Text(verbatim: score.summary)
                .font(SbuTheme.footnote.monospacedDigit())
                .foregroundStyle(SbuTheme.inkMuted)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(score.winner == .us ? "Partita vinta" : "Partita persa"))
        .accessibilityValue(Text("Set \(sets.us) a \(sets.them)"))
    }
}

#Preview("Light") {
    MatchResult(score: PadelMatch.finishedPreview.score, figureSize: SbuTheme.figureHeroMin)
        .background(SbuTheme.paper)
}

#Preview("Dark") {
    MatchResult(score: PadelMatch.finishedPreview.score, figureSize: SbuTheme.figureHeroMin)
        .background(SbuTheme.paper)
        .preferredColorScheme(.dark)
}
