import SbuKit
import SwiftUI

/// The Serie in Home: the days in a row that held, the points, and the five days around today.
struct SeriesCard: View {
    let tally: Tally

    var body: some View {
        let today = Day(.now)
        VStack(alignment: .leading, spacing: SbuTheme.space3) {
            VStack(alignment: .leading, spacing: SbuTheme.space1) {
                Text("Giorni di serie: \(tally.streak(on: today))")
                Text("Punti: \(tally.xp(on: today))")
            }
            .monospacedDigit()
            DayStrip(tally: tally)
        }
        .font(SbuTheme.body)
        .foregroundStyle(SbuTheme.ink)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SbuTheme.space4)
        .background(SbuTheme.surfaceRaised, in: .rect(cornerRadius: SbuTheme.radiusCard))
        .overlay {
            RoundedRectangle(cornerRadius: SbuTheme.radiusCard)
                .strokeBorder(SbuTheme.line, lineWidth: SbuTheme.hairline)
        }
    }
}

#Preview("Light") {
    SeriesCard(tally: Tally.sample())
        .padding()
}

#Preview("Dark") {
    SeriesCard(tally: Tally())
        .padding()
        .preferredColorScheme(.dark)
}
