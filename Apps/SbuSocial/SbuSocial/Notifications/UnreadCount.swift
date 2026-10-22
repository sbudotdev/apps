import Foundation

/// The unread count a messages page shows: in its title, "(3) Instagram" as in a Safari tab, or on
/// its badge.
nonisolated enum UnreadCount {
    /// The number the page shows, the title first; `nil` when it shows none.
    static func read(title: String, badge: String?) -> Int? {
        if let match = title.firstMatch(of: /^\((\d+)\+?\)/) { return Int(match.1) }
        if let match = badge?.firstMatch(of: /\d+/) { return Int(match.0) }
        return nil
    }

    /// Whether the site sent the page to its login: the session is over and there is nothing to count.
    static func isSignedOut(_ url: URL?) -> Bool {
        guard let url else { return false }
        return url.path.contains("/accounts/") || url.path.contains("/login") || url.host()?.hasPrefix("accounts.") == true
    }
}
