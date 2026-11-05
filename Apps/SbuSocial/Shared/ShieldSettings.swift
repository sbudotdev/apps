import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

/// What the Shield covers and why, shared by the app and its Screen Time extensions through the
/// app group. Every change goes through `update(in:_:)` and then `apply(to:now:)`, so the app and
/// the extensions always agree on one answer.
nonisolated struct ShieldSettings: Codable, Equatable {
    var intentions: [Intention] = []
    var sessions: [BlockSession] = []
    /// Apps that stay open while everything else is blocked.
    var allowList = FamilyActivitySelection()
    /// The running Blocca ora's end.
    var blockNowEnd: Date?

    static let maxIntentions = 8
    /// With one schedule each, the Intenzioni's returns and Blocca ora, this stays within the
    /// 20 schedules Screen Time allows.
    static let maxSessions = 10
    /// Screen Time takes at most 50 exceptions to "all apps".
    static let maxAllowed = 50
    /// Screen Time schedules last at least 15 minutes.
    static let blockNowLengths = [15, 30, 45, 60, 90, 120]
    /// The one store every part of the app writes the Shield to.
    static var storeName: ManagedSettingsStore.Name { .init("shield") }
    static var blockNowActivity: DeviceActivityName { .init("blocknow") }

    /// The one-off schedule whose start brings an Intenzione's Shield back.
    static func relockActivity(for id: Intention.ID) -> DeviceActivityName {
        .init("relock-\(id.uuidString)")
    }

    init() {}

    /// A field missing from an older save takes its default: failing here would wipe everything else.
    /// A field added later to `Intention` or `BlockSession` must be optional for the same reason.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        intentions = try container.decodeIfPresent([Intention].self, forKey: .intentions) ?? []
        sessions = try container.decodeIfPresent([BlockSession].self, forKey: .sessions) ?? []
        allowList = try container.decodeIfPresent(FamilyActivitySelection.self, forKey: .allowList) ?? FamilyActivitySelection()
        blockNowEnd = try container.decodeIfPresent(Date.self, forKey: .blockNowEnd)
    }

    /// Whether everything but the allowed apps is blocked now: Blocca ora or a Sessione is running.
    /// Read from the clock, so a missed callback cannot leave it wrong.
    func isBlocking(now: Date, calendar: Calendar = .current) -> Bool {
        (blockNowEnd ?? .distantPast) > now || sessions.contains { $0.isRunning(at: now, calendar: calendar) }
    }

    /// The apps their Intenzione covers now.
    func locked(now: Date, calendar: Calendar = .current) -> Set<ApplicationToken> {
        Set(intentions.filter { $0.isLocked(now: now, calendar: calendar) }.compactMap(\.app))
    }

    /// Adds an Intenzione, up to `maxIntentions`, or saves the changes to the one with the same id.
    mutating func put(_ intention: Intention) {
        if let index = intentions.firstIndex(where: { $0.id == intention.id }) {
            // The form edits a copy: what the Shield counted and learned meanwhile stays.
            let current = intentions[index]
            intentions[index] = intention
            intentions[index].opensDay = current.opensDay
            intentions[index].opens = current.opens
            intentions[index].unlockedUntil = current.unlockedUntil
            if intention.app == current.app { intentions[index].name = current.name }
        } else if intentions.count < Self.maxIntentions {
            intentions.append(intention)
        }
    }

    /// Adds a Sessione, up to `maxSessions`, or saves the changes to the one with the same id.
    mutating func put(_ session: BlockSession) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            sessions[index] = session
        } else if sessions.count < Self.maxSessions {
            sessions.append(session)
        }
    }

    /// Whether `app` already has an Intenzione other than the one with `id`.
    func isLimited(_ app: ApplicationToken, besides id: Intention.ID) -> Bool {
        intentions.contains { $0.app == app && $0.id != id }
    }

    /// Which Shield `app` shows now. `app` is missing when Screen Time shields a whole category.
    func kind(for app: ApplicationToken?, now: Date, calendar: Calendar = .current) -> ShieldKind {
        let isAllowed = app.map(allowList.applicationTokens.contains) ?? false
        if isBlocking(now: now, calendar: calendar), !isAllowed { return .session }
        if let app, let intention = intentions.first(where: { $0.app == app }) { return .intention(intention) }
        return .plain
    }

    static func load(from defaults: UserDefaults) -> ShieldSettings {
        defaults.data(forKey: "shield").flatMap { try? JSONDecoder().decode(ShieldSettings.self, from: $0) } ?? ShieldSettings()
    }

    func save(to defaults: UserDefaults) {
        defaults.set(try? JSONEncoder().encode(self), forKey: "shield")
    }

    /// Loads, changes and saves in one go. The app and the extensions each write here, so a copy
    /// held in memory and written back whole would erase what another one counted meanwhile.
    @discardableResult
    static func update(in defaults: UserDefaults, _ change: (inout ShieldSettings) -> Void) -> ShieldSettings {
        var settings = load(from: defaults)
        change(&settings)
        settings.save(to: defaults)
        return settings
    }

    /// Covers each Intenzione's app unless an opening is running, and everything but the allowed
    /// apps while a block runs; then counts the time in a block up to `now` in `defaults`.
    func apply(to store: ManagedSettingsStore, in defaults: UserDefaults, now: Date = .now) {
        let locked = locked(now: now)
        let isBlocking = isBlocking(now: now)
        store.shield.applications = locked.isEmpty ? nil : locked
        store.shield.applicationCategories = isBlocking ? .all(except: allowList.applicationTokens) : nil
        Tally.update(in: defaults) { $0.settle(isBlocking: isBlocking, now: now) }
    }
}
