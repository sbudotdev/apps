import DeviceActivity
import Foundation
import ManagedSettings

/// Runs when a Screen Time schedule starts or ends, and brings the Shield to what the settings
/// say now: an opening is over, or Blocca ora is.
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
        apply()
    }

    private func apply() {
        ShieldSettings.load(from: defaults).apply(to: store, in: defaults, now: .now.addingTimeInterval(Self.lead))
    }
}
