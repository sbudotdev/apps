import SbuKit
import SwiftUI

/// Accadde oggi, as in the Originale: a month's calendar where every day with photos from past
/// years carries a mark and how many are left to see. Today opens from the button on top; any
/// other day from its cell. The months move with the arrows.
struct OnThisDayScreen: View {
    let model: CleanModel

    @State private var month = Calendar.current.component(.month, from: .now)
    @ScaledMetric(relativeTo: .body) private var cellHeight: CGFloat = 56

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: SbuTheme.space1), count: 7)

    var body: some View {
        let queues = model.queues
        let counts = queues.dayCounts(inMonth: month)
        let today = DayOfYear(.now, calendar: calendar)
        ScrollView {
            VStack(alignment: .leading, spacing: SbuTheme.space4) {
                SbuFigure(
                    value: model.summary.onThisDayCount.formatted(),
                    fullStop: model.summary.onThisDayCount > 0 ? .set : .waiting,
                    context: Text("da vedere oggi, \(Date.now.formatted(.dateTime.day().month(.wide))), negli anni passati")
                )

                NavigationLink("Scorri quelle di oggi", value: Route.swipe(.onThisDay))
                    .buttonStyle(SbuFieldPillStyle())
                    .disabled(model.summary.onThisDayCount == 0)

                monthHeader

                LazyVGrid(columns: columns, spacing: SbuTheme.space1) {
                    ForEach(weekdaySymbols.indices, id: \.self) { index in
                        Text(weekdaySymbols[index])
                            .font(SbuTheme.caption)
                            .foregroundStyle(SbuTheme.inkMuted)
                            .frame(maxWidth: .infinity)
                            .accessibilityHidden(true)
                    }
                    ForEach(0..<leadingBlanks, id: \.self) { _ in
                        Color.clear
                            .frame(height: cellHeight)
                            .accessibilityHidden(true)
                    }
                    ForEach(1...daysInMonth, id: \.self) { day in
                        OnThisDayCell(day: DayOfYear(month: month, day: day), count: counts[day] ?? 0, isToday: today == DayOfYear(month: month, day: day))
                            .frame(height: cellHeight)
                    }
                }
            }
            .padding(SbuTheme.space4)
        }
        .background(SbuTheme.paper)
        .navigationTitle("Accadde oggi")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var monthHeader: some View {
        HStack {
            Button("Mese prima", systemImage: "chevron.backward") {
                month = month == 1 ? 12 : month - 1
            }
            .labelStyle(.iconOnly)
            .frame(minWidth: 44, minHeight: 44)
            Spacer()
            Text(DayOfYear(month: month, day: 1).date(in: 2000) ?? .now, format: .dateTime.month(.wide))
                .font(SbuTheme.title2)
                .foregroundStyle(SbuTheme.ink)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button("Mese dopo", systemImage: "chevron.forward") {
                month = month == 12 ? 1 : month + 1
            }
            .labelStyle(.iconOnly)
            .frame(minWidth: 44, minHeight: 44)
        }
        .fontWeight(.medium)
    }

    /// Weekday initials from the locale's first day of the week.
    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    /// The month as in the current year: a leap year's February shows its 29th.
    private var firstOfMonth: Date {
        let year = calendar.component(.year, from: .now)
        return calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? .now
    }

    private var leadingBlanks: Int {
        (calendar.component(.weekday, from: firstOfMonth) - calendar.firstWeekday + 7) % 7
    }

    private var daysInMonth: Int {
        // Every 29 February from past years has its cell, leap year or not.
        month == 2 ? 29 : calendar.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30
    }
}

#Preview("Light") {
    NavigationStack {
        OnThisDayScreen(model: .preview)
    }
    .environment(\.sbuAccent, .clean)
}

#Preview("Dark") {
    NavigationStack {
        OnThisDayScreen(model: .preview)
    }
    .environment(\.sbuAccent, .clean)
    .preferredColorScheme(.dark)
}
