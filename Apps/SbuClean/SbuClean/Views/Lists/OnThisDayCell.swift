import SbuKit
import SwiftUI

/// A day on the Accadde oggi calendar: its number, and when past years have photos to see, the
/// filled mark and how many, as a link to swipe them.
struct OnThisDayCell: View {
    let day: DayOfYear
    let count: Int
    let isToday: Bool

    private var spokenDay: Text {
        Text(day.date(in: 2000) ?? .now, format: .dateTime.day().month(.wide))
    }

    var body: some View {
        if count > 0 {
            NavigationLink(value: Route.swipe(isToday ? .onThisDay : .onDay(day))) {
                content
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("\(spokenDay), \(count) da vedere"))
        } else {
            content
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(spokenDay)
        }
    }

    private var content: some View {
        VStack(spacing: SbuTheme.space1) {
            Text(day.day, format: .number)
                .font(isToday ? SbuTheme.headline : SbuTheme.body)
                .foregroundStyle(count > 0 ? SbuTheme.ink : SbuTheme.inkMuted)
            if count > 0 {
                HStack(spacing: SbuTheme.space1) {
                    SbuRowMark(filled: true)
                    Text(count, format: .number)
                        .font(SbuTheme.caption)
                        .foregroundStyle(SbuTheme.inkMuted)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(count > 0 ? SbuTheme.surfaceRaised : .clear, in: .rect(cornerRadius: SbuTheme.radiusCard))
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: SbuTheme.radiusCard)
                    .strokeBorder(SbuTheme.ink, lineWidth: SbuTheme.hairline)
            }
        }
        .contentShape(.rect)
    }
}

#Preview("Light") {
    NavigationStack {
        HStack {
            OnThisDayCell(day: DayOfYear(month: 3, day: 12), count: 8, isToday: true)
            OnThisDayCell(day: DayOfYear(month: 3, day: 13), count: 0, isToday: false)
        }
        .frame(height: 56)
        .padding()
    }
}

#Preview("Dark") {
    NavigationStack {
        HStack {
            OnThisDayCell(day: DayOfYear(month: 3, day: 12), count: 8, isToday: false)
            OnThisDayCell(day: DayOfYear(month: 3, day: 13), count: 0, isToday: false)
        }
        .frame(height: 56)
        .padding()
    }
    .preferredColorScheme(.dark)
}
