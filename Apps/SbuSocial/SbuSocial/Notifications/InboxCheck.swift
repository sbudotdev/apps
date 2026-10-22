import BackgroundTasks
import Foundation
import UserNotifications
import WebKit

/// The background refresh that notifies you of new messages, as SocialLite does: it opens the
/// messages page of every Account where notifications are on, out of sight, as Safari would, reads
/// the unread count and posts one notification per Account with new ones. iOS decides when it runs,
/// so notifications can come late.
enum InboxCheck {
    /// The same in `BGTaskSchedulerPermittedIdentifiers` and in the app's `.backgroundTask`.
    static let identifier = "dev.sbu.social.inbox"

    /// Asks iOS for the next check, no sooner than in 15 minutes, while any notification is on.
    static func schedule(_ notifications: MessageNotifications = MessageNotifications()) {
        guard !notifications.platforms.isEmpty else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
            return
        }
        let request = BGAppRefreshTaskRequest(identifier: identifier)
        request.earliestBeginDate = .now + 15 * 60
        try? BGTaskScheduler.shared.submit(request)
    }

    /// One check of every Account, in parallel, within the 30 seconds iOS grants.
    static func run() async {
        let notifications = MessageNotifications()
        schedule(notifications)
        let accounts = AccountStore()
        await withTaskGroup(of: (Account, Int?).self) { group in
            for account in accounts.accounts where notifications.isOn(account.platform) {
                group.addTask { (account, await unread(on: account)) }
            }
            for await (account, count) in group {
                guard let count else { continue }
                let new = notifications.record(count, for: account.id)
                guard new > 0 else { continue }
                await post(new, on: account, numbered: accounts.accounts(on: account.platform).count > 1)
            }
        }
    }

    /// The unread count on the Account's messages page; `nil` when the page didn't load or the
    /// session is over.
    private static func unread(on account: Account) async -> Int? {
        let rules = account.platform.rules
        guard let inbox = rules.inbox else { return nil }
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore(forIdentifier: account.id)
        configuration.applicationNameForUserAgent = WebViewPool.safari
        let view = WKWebView(frame: .zero, configuration: configuration)
        view.load(URLRequest(url: inbox))
        // The page fills in its count after loading: look once a second for up to 20 seconds.
        var count: Int?
        var isLoaded = false
        for _ in 0..<20 {
            guard (try? await Task.sleep(for: .seconds(1))) != nil else { break }
            if UnreadCount.isSignedOut(view.url) { return nil }
            let page = try? await view.callAsyncJavaScript(script, arguments: ["badge": rules.unreadBadge ?? ""],
                                                          contentWorld: .defaultClient) as? [String: String]
            guard let page else { continue }
            isLoaded = page["state"] == "complete"
            count = UnreadCount.read(title: page["title"] ?? "", badge: page["badge"])
            if let count, count > 0 { break }
        }
        return count ?? (isLoaded ? 0 : nil)
    }

    /// Reads the page's title and badge, in a world apart from the page's own scripts.
    private static let script = """
        const element = badge ? document.querySelector(badge) : null;
        return {
            state: document.readyState,
            title: document.title,
            badge: element ? (element.getAttribute("aria-label") ?? "") + " " + element.textContent : ""
        };
        """

    private static func post(_ count: Int, on account: Account, numbered: Bool) async {
        let content = UNMutableNotificationContent()
        content.title = numbered
            ? "\(account.platform.name) · \(String(localized: "Account \(account.number)"))"
            : account.platform.name
        content.body = String(localized: "Hai \(count) messaggi nuovi.")
        content.sound = .default
        content.threadIdentifier = account.platform.rawValue
        content.userInfo = [NotificationRouter.accountKey: account.id.uuidString]
        // One notification per Account, replaced by the next.
        let request = UNNotificationRequest(identifier: "messages-\(account.id)", content: content, trigger: nil)
        try? await UNUserNotificationCenter.current().add(request)
    }
}
