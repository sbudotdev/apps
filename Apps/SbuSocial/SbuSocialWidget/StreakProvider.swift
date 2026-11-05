import Foundation
import WidgetKit

/// Reads the Serie from the app group. It changes by itself only at midnight: one more day, or
/// the first of a new one. The app and the extensions ask for a reload when a day breaks.
struct StreakProvider: TimelineProvider {
    private let defaults = UserDefaults(suiteName: "group.dev.sbu.social") ?? .standard

    func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, streak: 4)
    }

    func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : entry(at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let now = Date.now
        let calendar = Calendar.current
        let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now)) ?? now.addingTimeInterval(86_400)
        completion(Timeline(entries: [entry(at: now)], policy: .after(midnight)))
    }

    private func entry(at date: Date) -> StreakEntry {
        StreakEntry(date: date, streak: Tally.load(from: defaults).streak(on: Day(date)))
    }
}
