import SbuKit
import SwiftUI

/// Half of the court: the whole half is the button that gives a point to its pair, so it can be
/// hit without looking. Shows the game call large, the games and sets small, and the full stop
/// on the pair that serves.
struct SideButton: View {
    let side: Side
    let score: MatchScore
    let figureSize: CGFloat
    let action: () -> Void

    private var name: LocalizedStringKey { side == .us ? "Noi" : "Loro" }
    private var serves: Bool { score.winner == nil && score.server == side }

    var body: some View {
        Button(action: action) {
            VStack(spacing: SbuTheme.space1) {
                HStack(spacing: SbuTheme.space1) {
                    Text(name)
                        .font(SbuTheme.headline)
                        .foregroundStyle(SbuTheme.inkMuted)
                    SbuFullStop(serves ? .set : .absent, size: .mark)
                }
                Text(verbatim: score.call(for: side))
                    .font(.sbuFigure(size: figureSize))
                    .foregroundStyle(SbuTheme.ink)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .contentTransition(.numericText())
                // Two lines, so neither is cut at the largest text sizes.
                Group {
                    Text("Game \(score.games[side])")
                    Text("Set \(score.setsWon[side])")
                }
                .font(SbuTheme.footnote)
                .foregroundStyle(SbuTheme.inkMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }
            .padding(SbuTheme.space1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(SbuTheme.surfaceRaised, in: .rect(cornerRadius: SbuTheme.radiusCard))
            .overlay(RoundedRectangle(cornerRadius: SbuTheme.radiusCard).strokeBorder(SbuTheme.line))
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(score.winner != nil)
        // On the Button itself, so VoiceOver reads one element with the button trait.
        .accessibilityLabel(Text(side == .us ? "Punto a Noi" : "Punto a Loro"))
        .accessibilityValue(accessibilityValue)
    }

    private var accessibilityValue: Text {
        let base = Text(verbatim: score.call(for: side) + ", ")
            + Text("Game \(score.games[side])") + Text(verbatim: ", ") + Text("Set \(score.setsWon[side])")
        return serves ? base + Text(verbatim: ", ") + Text("al servizio") : base
    }
}

#Preview("Light") {
    SideButton(side: .us, score: PadelMatch().score, figureSize: SbuTheme.figureWidget) {}
        .frame(width: 180, height: 220)
        .environment(\.sbuAccent, .steps)
}

#Preview("Dark") {
    SideButton(side: .them, score: PadelMatch().score, figureSize: SbuTheme.figureWidget) {}
        .frame(width: 180, height: 220)
        .environment(\.sbuAccent, .steps)
        .preferredColorScheme(.dark)
}
