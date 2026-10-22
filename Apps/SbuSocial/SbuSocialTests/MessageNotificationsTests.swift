import Foundation
import Testing
@testable import SbuSocial

struct MessageNotificationsTests {
    private let defaults = UserDefaults(suiteName: "MessageNotificationsTests-\(UUID())")!

    @Test(arguments: [
        ("(3) Instagram", "", 3),
        ("(12+) Snapchat", "", 12),
        ("Inbox • Direct", "Direct 2", 2),
        ("(1) Inbox • Direct", "Direct 5", 1),
    ])
    func readsTheCountFromTitleThenBadge(title: String, badge: String, count: Int) {
        #expect(UnreadCount.read(title: title, badge: badge) == count)
    }

    @Test func noNumberOnThePageIsNoCount() {
        #expect(UnreadCount.read(title: "Instagram", badge: "Direct") == nil)
    }

    @Test(arguments: [
        ("https://www.instagram.com/accounts/login/?next=/direct/inbox/", true),
        ("https://accounts.snapchat.com/v2/login", true),
        ("https://www.instagram.com/direct/inbox/", false),
        ("https://web.snapchat.com/", false),
    ])
    func loginPagesMeanSignedOut(address: String, signedOut: Bool) throws {
        #expect(UnreadCount.isSignedOut(try #require(URL(string: address))) == signedOut)
    }

    @Test func onlyInstagramAndSnapchatHaveAMessagesPage() {
        #expect(MessageNotifications.available == [.instagram, .snapchat])
    }

    @Test func notificationsStartOffAndPersist() {
        #expect(MessageNotifications(defaults: defaults).platforms.isEmpty)
        MessageNotifications(defaults: defaults).set(.instagram, to: true)
        #expect(MessageNotifications(defaults: defaults).isOn(.instagram))
    }

    @Test func onlyMessagesArrivedSinceTheLastCheckAreNew() {
        let notifications = MessageNotifications(defaults: defaults)
        let account = UUID()
        #expect(notifications.record(2, for: account) == 2)
        #expect(notifications.record(2, for: account) == 0)
        #expect(notifications.record(0, for: account) == 0)
        #expect(MessageNotifications(defaults: defaults).record(3, for: account) == 3)
    }
}
