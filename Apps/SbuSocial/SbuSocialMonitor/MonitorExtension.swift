import DeviceActivity
import Foundation
import ManagedSettings

/// Runs when a Screen Time schedule starts or ends, or the day's screen time reaches the
/// Obiettivo giornaliero. It brings the Shield to what the settings say now, pays a finished
/// block its points and marks the day the goal was reached.
final class MonitorExtension: DeviceActivityMonitor {
    /// iOS may call a few seconds early; the Shield is decided for a moment just after the change.
    private static let lead: TimeInterval = 30

    private let defaults = UserDefaults(suiteName: "group.dev.sbu.social") ?? .standard
    private let store = ManagedSettingsStore(named: ShieldSettings.storeName)

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // The start of a relock schedule is the Shield's return: the schedule has done its job.
        if activity.rawValue.hasPrefix("relock-") {
            DeviceActivityCenter().stopMonitoring([activity])
        }
        apply()
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        let now = Date.now
        let settings = ShieldSettings.load(from: defaults)
        if activity == ShieldSettings.blockNowActivity, let end = settings.blockNowEnd, end <= now.addingTimeInterval(Self.lead) {
            Tally.update(in: defaults) { $0.completeBlock("blocknow-\(Int(end.timeIntervalSince1970))", xp: ShieldSettings.blockNowXP, on: Day(now)) }
        }
        // A Sessione's schedule ends every day: it is finished only if it ran, on one of its days.
        if let session = settings.sessions.first(where: { $0.activity == activity }), session.isRunning(at: now.addingTimeInterval(-120)) {
            Tally.update(in: defaults) { $0.completeBlock(session.id.uuidString, xp: session.xp, on: Day(now)) }
        }
        apply()
    }

    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        guard event == ShieldSettings.goalEvent else { return }
        let now = Date.now
        let goal = TimeInterval(ShieldSettings.load(from: defaults).goalMinutes * 60)
        // On iOS 26 the threshold is reported to fire seconds after monitoring starts: a goal
        // cannot be reached in less time than the day has had.
        guard now.timeIntervalSince(Calendar.current.startOfDay(for: now)) >= goal else { return }
        let today = Day(now)
        guard !Tally.load(from: defaults).overGoalDays.contains(today) else { return }
        Tally.update(in: defaults) { $0.markOverGoal(on: today) }
        let length = Duration.seconds(goal).formatted(.units(allowed: [.hours, .minutes], width: .wide))
        Task {
            await ShieldNotice.post(id: "goal", title: String(localized: "Hai raggiunto l'Obiettivo giornaliero"),
                                    body: String(localized: "\(length) di schermo oggi. Il giorno non conta per la serie."))
        }
    }

    private func apply() {
        ShieldSettings.load(from: defaults).apply(to: store, in: defaults, now: .now.addingTimeInterval(Self.lead))
    }
}
