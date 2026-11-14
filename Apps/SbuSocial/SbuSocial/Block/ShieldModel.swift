import DeviceActivity
import FamilyControls
import ManagedSettings
import Observation
import UserNotifications
import WidgetKit

/// The Shield's state for the app: Screen Time permission, the Intenzioni, Blocca ora, the
/// Sessioni and the App consentite, with the time in a block they add up to.
/// Every change loads the app group afresh, saves and applies the one answer of `ShieldSettings`,
/// as the extensions do.
@Observable
final class ShieldModel {
    private(set) var settings: ShieldSettings
    private(set) var tally: Tally {
        didSet {
            let today = Day(.now)
            if tally.streak(on: today) != oldValue.streak(on: today) {
                WidgetCenter.shared.reloadTimelines(ofKind: Tally.widgetKind)
            }
        }
    }
    private(set) var isAuthorized: Bool

    @ObservationIgnored private let defaults: UserDefaults
    /// Both `nil` on a made-up Shield: screenshots and UI tests must not change your real one.
    @ObservationIgnored private let store: ManagedSettingsStore?
    @ObservationIgnored private let center: DeviceActivityCenter?

    /// - Parameter isDemo: On the made-up Shield of screenshots and UI tests there is no Screen
    ///   Time to ask for: the Simulator has none. It never touches the real Shield or schedules.
    init(defaults: UserDefaults = .appGroup, isDemo: Bool = false) {
        self.defaults = defaults
        store = isDemo ? nil : ManagedSettingsStore(named: ShieldSettings.storeName)
        center = isDemo ? nil : DeviceActivityCenter()
        settings = ShieldSettings.load(from: defaults)
        tally = Tally.load(from: defaults)
        isAuthorized = isDemo || AuthorizationCenter.shared.authorizationStatus == .approved
    }

    var blockNowEnd: Date? { settings.blockNowEnd }

    /// The next moment the Shield may change by itself: an opening or Blocca ora ends, or a
    /// Sessione reaches one of its hours.
    func nextChange(after now: Date = .now, calendar: Calendar = .current) -> Date? {
        let hours = settings.sessions.filter(\.isOn).flatMap { [$0.start, $0.end] }.compactMap { minutes in
            calendar.nextDate(after: now, matching: DateComponents(hour: minutes / 60, minute: minutes % 60), matchingPolicy: .nextTime)
        }
        return (settings.intentions.compactMap(\.unlockedUntil) + [settings.blockNowEnd].compactMap(\.self) + hours)
            .filter { $0 > now }
            .min()
    }

    /// Asks for Screen Time the first time you choose an app or block, never earlier.
    func authorize() async -> Bool {
        if !isAuthorized {
            try? await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
            // Allowed just now: the Serie begins today and the day's watch starts, with the
            // notification that says the Obiettivo giornaliero was reached.
            if isAuthorized {
                refresh()
                _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            }
        }
        return isAuthorized
    }

    // MARK: Intenzioni

    /// Adds an Intenzione or saves its changes.
    func save(_ intention: Intention) {
        update { $0.put(intention) }
        // An opening is announced by a notification: ask when the first Intenzione exists.
        Task { _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) }
    }

    func remove(_ intention: Intention) {
        center?.stopMonitoring([ShieldSettings.relockActivity(for: intention.id)])
        update { $0.intentions.removeAll { $0.id == intention.id } }
    }

    // MARK: Blocca ora

    /// Blocks everything but the allowed apps from now for `minutes`.
    func startBlockNow(minutes: Int, now: Date = .now) {
        let end = now.addingTimeInterval(TimeInterval(minutes * 60))
        try? center?.startMonitoring(ShieldSettings.blockNowActivity, during: .oneOff(from: now, to: end))
        update { $0.blockNowEnd = end }
    }

    /// Ends it early: an unfinished block gives no points.
    func endBlockNow() {
        center?.stopMonitoring([ShieldSettings.blockNowActivity])
        update { $0.blockNowEnd = nil }
    }

    // MARK: Sessioni

    /// Adds a Sessione or saves its changes, and schedules it again.
    /// Saved before the schedule stops: if iOS ends the interval then, the monitor already sees
    /// the change, and `BlockSession.isFinished(at:)` pays only a Sessione that reached its end.
    func save(_ session: BlockSession) {
        update { $0.put(session) }
        center?.stopMonitoring([session.activity])
        if session.isOn {
            try? center?.startMonitoring(session.activity, during: session.schedule)
        }
    }

    func remove(_ session: BlockSession) {
        update { $0.sessions.removeAll { $0.id == session.id } }
        center?.stopMonitoring([session.activity])
    }

    /// The apps that stay open during Blocca ora and the Sessioni.
    func allow(_ selection: FamilyActivitySelection) {
        update { $0.allowList = selection }
    }

    // MARK: Obiettivo giornaliero

    var goalMinutes: Int {
        get { settings.goalMinutes }
        set {
            update { $0.goalMinutes = newValue }
            watchDay()
        }
    }

    /// Watches the whole day, every day, for the moment its screen time reaches the goal.
    private func watchDay() {
        guard isAuthorized else { return }
        let day = DeviceActivitySchedule(intervalStart: DateComponents(hour: 0, minute: 0),
                                         intervalEnd: DateComponents(hour: 23, minute: 59), repeats: true)
        let threshold = DateComponents(minute: settings.goalMinutes)
        // No apps, categories or sites named: the event counts all of them.
        let goal = if #available(iOS 17.4, *) {
            // Counted from midnight, not from when the watch began.
            DeviceActivityEvent(applications: [], categories: [], webDomains: [], threshold: threshold, includesPastActivity: true)
        } else {
            DeviceActivityEvent(applications: [], categories: [], webDomains: [], threshold: threshold)
        }
        try? center?.startMonitoring(ShieldSettings.dayActivity, during: day, events: [ShieldSettings.goalEvent: goal])
    }

    /// The first-run setup is over, finished or skipped.
    func finishSetup() {
        update { $0.isSetUp = true }
    }

    // MARK: Serie, punti, Missione del giorno

    func complete(_ task: QuestTask, now: Date = .now) {
        tally = Tally.update(in: defaults) { $0.complete(task, on: Day(now)) }
    }

    func restoreStreak() {
        tally = Tally.update(in: defaults) { $0.restoreStreak() }
    }

    func resetRecord() {
        tally = Tally.update(in: defaults) { $0.resetRecord() }
    }

    /// When the app comes back, or the Shield changes by itself with the app open: the extensions
    /// may have changed it meanwhile, or iOS was late.
    func refresh(now: Date = .now) {
        settings = ShieldSettings.load(from: defaults)
        if isAuthorized {
            Tally.update(in: defaults) { $0.begin(on: Day(now)) }
            if center?.activities.contains(ShieldSettings.dayActivity) == false { watchDay() }
        }
        if let end = settings.blockNowEnd, end <= now {
            // The monitor extension pays it too, whichever comes first: the key makes it once.
            Tally.update(in: defaults) { $0.completeBlock("blocknow-\(Int(end.timeIntervalSince1970))", xp: ShieldSettings.blockNowXP, on: Day(now)) }
            center?.stopMonitoring([ShieldSettings.blockNowActivity])
            update { $0.blockNowEnd = nil }
        } else {
            settings.apply(to: store, in: defaults, now: now)
            tally = Tally.load(from: defaults)
        }
    }

    private func update(_ change: (inout ShieldSettings) -> Void) {
        settings = ShieldSettings.update(in: defaults, change)
        settings.apply(to: store, in: defaults)
        tally = Tally.load(from: defaults)
    }
}
