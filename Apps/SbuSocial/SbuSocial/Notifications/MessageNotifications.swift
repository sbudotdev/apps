import Foundation
import Observation

/// The Platforms whose messages you are notified of, off by default, and the unread count last seen
/// on each Account, kept in UserDefaults.
@Observable
final class MessageNotifications {
    private(set) var platforms: Set<Platform>
    @ObservationIgnored private var unread: [UUID: Int]
    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        platforms = defaults.data(forKey: "notifiedPlatforms").flatMap { try? JSONDecoder().decode(Set<Platform>.self, from: $0) } ?? []
        unread = defaults.data(forKey: "unreadMessages").flatMap { try? JSONDecoder().decode([UUID: Int].self, from: $0) } ?? [:]
    }

    /// The Platforms Sbu Social can check: those whose rules name a messages page.
    static var available: [Platform] {
        Platform.allCases.filter { $0.rules.inbox != nil }
    }

    func isOn(_ platform: Platform) -> Bool {
        platforms.contains(platform)
    }

    func set(_ platform: Platform, to isOn: Bool) {
        if isOn { platforms.insert(platform) } else { platforms.remove(platform) }
        defaults.set(try? JSONEncoder().encode(platforms), forKey: "notifiedPlatforms")
    }

    /// Records an Account's unread count and returns how many arrived since the last check: none when
    /// the count stayed or dropped because you read them.
    func record(_ count: Int, for account: UUID) -> Int {
        let new = max(count - unread[account, default: 0], 0)
        unread[account] = count
        defaults.set(try? JSONEncoder().encode(unread), forKey: "unreadMessages")
        return new
    }
}
