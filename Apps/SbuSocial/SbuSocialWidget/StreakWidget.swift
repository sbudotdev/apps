import SbuKit
import SwiftUI
import WidgetKit

/// The Serie on the Home Screen: the days in a row that held, closed by the full stop while it holds.
struct StreakWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Tally.widgetKind, provider: StreakProvider()) { entry in
            SbuWidgetFigure(value: entry.streak.formatted(), label: Text("giorni di serie"),
                            fullStop: entry.streak > 0 ? .set : .waiting, accent: .social)
        }
        .configurationDisplayName("Serie")
        .description("I giorni di fila in cui hai tenuto.")
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    StreakWidget()
} timeline: {
    StreakEntry(date: .now, streak: 4)
    StreakEntry(date: .now, streak: 0)
}
