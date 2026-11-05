import SbuKit
import SwiftUI

/// Five days, from the day before yesterday to the day after tomorrow, each marked when it held.
struct DayStrip: View {
    let tally: Tally

    var body: some View {
        let now = Date.now
        let today = Day(now)
        HStack(alignment: .top, spacing: 0) {
            ForEach(-2...2, id: \.self) { offset in
                let date = Calendar.current.date(byAdding: .day, value: offset, to: now) ?? now
                let isKept = tally.isKept(Day(date), today: today)
                VStack(spacing: SbuTheme.space1) {
                    Text(date, format: .dateTime.weekday(.abbreviated))
                        .foregroundStyle(SbuTheme.inkMuted)
                    Text(date, format: .dateTime.day())
                        .fontWeight(offset == 0 ? .semibold : .regular)
                    SbuRowMark(filled: isKept)
                }
                .font(SbuTheme.footnote)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(label(for: date, isKept: isKept, isAhead: offset > 0))
            }
        }
    }

    private func label(for date: Date, isKept: Bool, isAhead: Bool) -> Text {
        let day = date.formatted(.dateTime.weekday(.wide).day())
        if isKept { return Text("\(day), tenuto") }
        return isAhead ? Text("\(day), da venire") : Text("\(day), non tenuto")
    }
}

#Preview("Light") {
    DayStrip(tally: Tally.sample())
        .padding()
}

#Preview("Dark") {
    DayStrip(tally: Tally.sample())
        .padding()
        .preferredColorScheme(.dark)
}
