import DeviceActivity
import FamilyControls
import ManagedSettings
import Observation
import UserNotifications

/// The Shield's state for the app: Screen Time permission, the Intenzioni, Blocca ora, the
/// Sessioni and the App consentite, with the time in a block they add up to.
/// Every change loads the app group afresh, saves and applies the one answer of `ShieldSettings`,
/// as the extensions do.
@Observable
final class ShieldModel {
    private(set) var settings: ShieldSettings
    private(set) var tally: Tally
    private(set) var isAuthorized: Bool

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let store = ManagedSettingsStore(named: ShieldSettings.storeName)
    @ObservationIgnored private let center = DeviceActivityCenter()

    /// - Parameter isDemo: On the made-up Shield of screenshots and UI tests there is no Screen
    ///   Time to ask for: the Simulator has none.
    init(defaults: UserDefaults = .appGroup, isDemo: Bool = false) {
        self.defaults = defaults
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
        center.stopMonitoring([ShieldSettings.relockActivity(for: intention.id)])
        update { $0.intentions.removeAll { $0.id == intention.id } }
    }

    // MARK: Blocca ora

    /// Blocks everything but the allowed apps from now for `minutes`.
    func startBlockNow(minutes: Int, now: Date = .now) {
        let end = now.addingTimeInterval(TimeInterval(minutes * 60))
        try? center.startMonitoring(ShieldSettings.blockNowActivity, during: .oneOff(from: now, to: end))
        update { $0.blockNowEnd = end }
    }

    func endBlockNow() {
        center.stopMonitoring([ShieldSettings.blockNowActivity])
        update { $0.blockNowEnd = nil }
    }

    // MARK: Sessioni

    /// Adds a Sessione or saves its changes, and schedules it again.
    func save(_ session: BlockSession) {
        center.stopMonitoring([session.activity])
        if session.isOn {
            try? center.startMonitoring(session.activity, during: session.schedule)
        }
        update { $0.put(session) }
    }

    func remove(_ session: BlockSession) {
        center.stopMonitoring([session.activity])
        update { $0.sessions.removeAll { $0.id == session.id } }
    }

    /// The apps that stay open during Blocca ora and the Sessioni.
    func allow(_ selection: FamilyActivitySelection) {
        update { $0.allowList = selection }
    }

    /// When the app comes back, or the Shield changes by itself with the app open: the extensions
    /// may have changed it meanwhile, or iOS was late.
    func refresh(now: Date = .now) {
        settings = ShieldSettings.load(from: defaults)
        if let end = settings.blockNowEnd, end <= now {
            endBlockNow()
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
