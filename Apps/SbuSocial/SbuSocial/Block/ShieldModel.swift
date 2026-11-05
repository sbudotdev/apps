import DeviceActivity
import FamilyControls
import ManagedSettings
import Observation
import UserNotifications

/// The Shield's state for the app: Screen Time permission, the Intenzioni and Blocca ora.
/// Every change loads the app group afresh, saves and applies the one answer of `ShieldSettings`,
/// as the extensions do.
@Observable
final class ShieldModel {
    private(set) var settings: ShieldSettings
    private(set) var isAuthorized: Bool

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let store = ManagedSettingsStore(named: ShieldSettings.storeName)
    @ObservationIgnored private let center = DeviceActivityCenter()

    init(defaults: UserDefaults = .appGroup) {
        self.defaults = defaults
        settings = ShieldSettings.load(from: defaults)
        isAuthorized = AuthorizationCenter.shared.authorizationStatus == .approved
    }

    var blockNowEnd: Date? { settings.blockNowEnd }

    /// The next moment the Shield changes by itself: an opening or Blocca ora ends.
    func nextChange(after now: Date = .now) -> Date? {
        (settings.intentions.compactMap(\.unlockedUntil) + [settings.blockNowEnd].compactMap(\.self))
            .filter { $0 > now }
            .min()
    }

    /// Asks for Screen Time the first time you choose an app, never earlier.
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

    /// When the app comes back, or an opening or a block ends with the app open: the extensions
    /// may have changed the Shield meanwhile, or iOS was late.
    func refresh(now: Date = .now) {
        settings = ShieldSettings.load(from: defaults)
        if let end = settings.blockNowEnd, end <= now {
            endBlockNow()
        } else {
            settings.apply(to: store, now: now)
        }
    }

    private func update(_ change: (inout ShieldSettings) -> Void) {
        settings = ShieldSettings.update(in: defaults, change)
        settings.apply(to: store)
    }
}
