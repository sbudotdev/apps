import Foundation

/// Whether the app runs on your Shield, or on a made-up one for screenshots and UI tests.
/// The made-up ones never read or write your settings.
enum LaunchMode {
    case user
    /// The sample Shield: screenshots and flow tests on data.
    case sample
    /// Nothing set up yet: first-run flow tests.
    case empty

    static var current: LaunchMode {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "FASTLANE_SNAPSHOT") || defaults.bool(forKey: "SBU_SAMPLE_STORE") { return .sample }
        if defaults.bool(forKey: "SBU_EMPTY_STORE") { return .empty }
        return .user
    }

    /// What this mode reads and writes: the app group, or a fresh suite that starts over at each launch.
    var defaults: UserDefaults {
        guard self != .user else { return .appGroup }
        let suite = "dev.sbu.social.demo"
        let defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        if self == .sample {
            ShieldSettings.sample().save(to: defaults)
            Tally.sample().save(to: defaults)
        }
        return defaults
    }
}
