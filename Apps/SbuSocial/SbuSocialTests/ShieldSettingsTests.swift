import Foundation
import ManagedSettings
import Testing
@testable import SbuSocial

struct ShieldSettingsTests {
    private let now = Date(timeIntervalSince1970: 1_792_000_000)
    private let calendar = Calendar(identifier: .gregorian)

    private func freshDefaults() -> UserDefaults {
        UserDefaults(suiteName: "ShieldSettingsTests-\(UUID())")!
    }

    /// A stand-in for an app as Screen Time hands it over: tokens are opaque data.
    private func app(_ byte: UInt8) throws -> ApplicationToken {
        let json = #"{"data":"\#(Data([byte]).base64EncodedString())"}"#
        return try JSONDecoder().decode(ApplicationToken.self, from: Data(json.utf8))
    }

    @Test func emptyUntilYouAddAnIntention() {
        let settings = ShieldSettings.load(from: freshDefaults())
        #expect(settings.intentions.isEmpty)
        #expect(!settings.isBlocking(now: now))
        #expect(settings.locked(now: now, calendar: calendar).isEmpty)
    }

    @Test func everythingSurvivesARelaunch() throws {
        let defaults = freshDefaults()
        var settings = ShieldSettings()
        settings.put(Intention(app: try app(1), maxOpens: 3))
        settings.blockNowEnd = now
        settings.save(to: defaults)
        #expect(ShieldSettings.load(from: defaults) == settings)
    }

    @Test func aSavedShieldWithoutTheNewerFieldsKeepsWhatItHas() {
        let defaults = freshDefaults()
        defaults.set(Data(#"{"blockNowEnd":1000}"#.utf8), forKey: "shield")
        #expect(ShieldSettings.load(from: defaults).blockNowEnd == Date(timeIntervalSinceReferenceDate: 1000))
    }

    @Test func aChangeKeepsWhatAnExtensionWroteMeanwhile() throws {
        let defaults = freshDefaults()
        var settings = ShieldSettings()
        settings.put(Intention(app: try app(1)))
        settings.save(to: defaults)

        // The Shield's button counts an opening while the app still holds its older copy.
        ShieldSettings.update(in: defaults) { $0.intentions[0].open(now: now, calendar: calendar) }
        let saved = ShieldSettings.update(in: defaults) { $0.blockNowEnd = now }

        #expect(saved.intentions[0].opens == 1)
        #expect(saved.blockNowEnd == now)
        #expect(ShieldSettings.load(from: defaults) == saved)
    }

    @Test func blockNowHoldsUntilItsEnd() {
        var settings = ShieldSettings()
        settings.blockNowEnd = now.addingTimeInterval(60)
        #expect(settings.isBlocking(now: now))
        #expect(!settings.isBlocking(now: now.addingTimeInterval(60)))
    }

    @Test func aRunningSessionBlocksToo() {
        var settings = ShieldSettings()
        // `now` is 17:46 UTC: a session over the whole afternoon and evening holds it.
        var utc = calendar
        utc.timeZone = .gmt
        settings.put(BlockSession(name: "Sera", start: 17 * 60, end: 23 * 60))
        #expect(settings.isBlocking(now: now, calendar: utc))
        #expect(settings.kind(for: nil, now: now, calendar: utc) == .session)
        #expect(!settings.isBlocking(now: now.addingTimeInterval(6 * 3600), calendar: utc))
    }

    @Test func puttingASessionAgainReplacesItAndTenIsTheMost() {
        var settings = ShieldSettings()
        var session = BlockSession(name: "Cena", start: 18 * 60, end: 19 * 60)
        settings.put(session)
        session.name = "Cena lunga"
        settings.put(session)
        #expect(settings.sessions.map(\.name) == ["Cena lunga"])

        for _ in 0..<12 { settings.put(BlockSession(name: "Altra", start: 0, end: 60)) }
        #expect(settings.sessions.count == ShieldSettings.maxSessions)
    }

    @Test func onlyIntentionsWithNoOpeningRunningAreLocked() throws {
        var settings = ShieldSettings()
        settings.put(Intention(app: try app(1)))
        settings.put(Intention(app: try app(2)))
        settings.intentions[1].open(now: now, calendar: calendar)
        #expect(settings.locked(now: now, calendar: calendar) == [try app(1)])
    }

    @Test func puttingAnIntentionAgainReplacesIt() throws {
        var settings = ShieldSettings()
        var intention = Intention(app: try app(1))
        settings.put(intention)
        intention.maxOpens = 4
        settings.put(intention)
        #expect(settings.intentions.map(\.maxOpens) == [4])
    }

    @Test func savingAnEditedIntentionKeepsWhatTheShieldCountedMeanwhile() throws {
        var settings = ShieldSettings()
        var edited = Intention(app: try app(1))
        settings.put(edited)
        // The form holds its copy while the Shield counts an opening and learns the app's name.
        settings.intentions[0].open(now: now, calendar: calendar)
        settings.intentions[0].name = "Instagram"
        edited.maxOpens = 4
        settings.put(edited)

        let saved = settings.intentions[0]
        #expect(saved.maxOpens == 4)
        #expect(saved.opens == 1)
        #expect(saved.unlockedUntil == now.addingTimeInterval(600))
        #expect(saved.name == "Instagram")
    }

    @Test func anAppTakesOneIntentionOnly() throws {
        var settings = ShieldSettings()
        let first = Intention(app: try app(1))
        settings.put(first)
        #expect(settings.isLimited(try app(1), besides: UUID()))
        // Editing the Intenzione that already holds the app is not a second one.
        #expect(!settings.isLimited(try app(1), besides: first.id))
        #expect(!settings.isLimited(try app(2), besides: UUID()))
    }

    @Test func theSampleShieldHasOpeningsCountedToday() {
        let sample = ShieldSettings.sample(now: now, calendar: calendar)
        #expect(sample.intentions.count == 2)
        #expect(sample.intentions.allSatisfy { $0.opens(on: Day(now, calendar: calendar)) > 0 })
    }

    @Test func atMostEightIntentions() {
        var settings = ShieldSettings()
        for _ in 0..<9 { settings.put(Intention()) }
        #expect(settings.intentions.count == ShieldSettings.maxIntentions)
    }

    // MARK: Which Shield

    @Test func outsideABlockALimitedAppShowsItsIntention() throws {
        var settings = ShieldSettings()
        settings.put(Intention(app: try app(1), maxOpens: 3))
        #expect(settings.kind(for: try app(1), now: now) == .intention(settings.intentions[0]))
    }

    @Test func whileBlockingTheShieldIsTheSessionOne() throws {
        var settings = ShieldSettings()
        settings.put(Intention(app: try app(1)))
        settings.blockNowEnd = now.addingTimeInterval(60)
        #expect(settings.kind(for: try app(1), now: now) == .session)
        #expect(settings.kind(for: try app(2), now: now) == .session)
        #expect(settings.kind(for: nil, now: now) == .session)
    }

    @Test func anAllowedAppKeepsItsIntentionShieldWhileBlocking() throws {
        var settings = ShieldSettings()
        settings.put(Intention(app: try app(1)))
        settings.allowList.applicationTokens = [try app(1)]
        settings.blockNowEnd = now.addingTimeInterval(60)
        #expect(settings.kind(for: try app(1), now: now) == .intention(settings.intentions[0]))
    }

    @Test func anythingElseIsPlain() throws {
        var settings = ShieldSettings()
        settings.put(Intention(app: try app(1)))
        #expect(settings.kind(for: try app(2), now: now) == .plain)
        #expect(settings.kind(for: nil, now: now) == .plain)
    }
}
