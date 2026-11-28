import SbuKit
import SwiftUI

/// The scoreboard as it is written on a scoresheet: a row for each pair, a column for each set,
/// the set in play last. In a finished set the winner's games are in ink, the loser's muted; a
/// tie-break adds the loser's points small, as in "7-6⁵".
struct SetTable: View {
    let score: MatchScore
    /// The font of the games: `statSmall` scaled on the iPhone, a text style on the watch.
    let digitFont: Font

    var body: some View {
        let columns = score.columns
        Grid(alignment: .leading, horizontalSpacing: SbuTheme.space3, verticalSpacing: SbuTheme.space1) {
            GridRow {
                Text("Set")
                ForEach(columns.indices, id: \.self) { index in
                    Text(verbatim: String(index + 1))
                        .gridColumnAlignment(.center)
                }
            }
            .font(SbuTheme.caption)
            .textCase(.uppercase)
            .tracking(SbuTheme.captionTracking)
            .foregroundStyle(SbuTheme.inkMuted)
            ForEach(Side.allCases, id: \.self) { side in
                GridRow {
                    Text(side.name)
                        .font(SbuTheme.headline)
                        .foregroundStyle(SbuTheme.inkMuted)
                    ForEach(columns.indices, id: \.self) { index in
                        cell(columns[index], set: index, side: side)
                    }
                }
            }
        }
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Set"))
        .accessibilityValue(accessibilityValue)
    }

    private func cell(_ set: Pair, set index: Int, side: Side) -> some View {
        let isFinished = index < score.sets.count
        let lost = isFinished && set[side] < set[side.other]
        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            Text(verbatim: String(set[side]))
                .font(digitFont)
                .contentTransition(.numericText())
            if lost, let tiebreak = score.tiebreaks[index] {
                Text(verbatim: String(tiebreak[side]))
                    .font(SbuTheme.caption)
            }
        }
        .foregroundStyle(lost ? SbuTheme.inkMuted : SbuTheme.ink)
    }

    /// "Set 1: Noi 6, Loro 4. Set 2: Noi 3, Loro 2."
    private var accessibilityValue: Text {
        score.columns.indices.reduce(Text(verbatim: "")) { text, index in
            let set = score.columns[index]
            return text + Text("Set \(index + 1): Noi \(set.us), Loro \(set.them). ")
        }
    }
}

#Preview("Light") {
    SetTable(score: PadelMatch.preview.score, digitFont: SbuTheme.statSmall)
        .padding()
        .background(SbuTheme.paper)
}

#Preview("Dark") {
    SetTable(score: PadelMatch.preview.score, digitFont: SbuTheme.statSmall)
        .padding()
        .background(SbuTheme.paper)
        .preferredColorScheme(.dark)
}
