import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings

/// What the Shield covers and why, shared by the app and its Screen Time extensions through the
/// app group. Every change goes through `update(in:_:)` and then `apply(to:now:)`, so the app and
/// the extensions always agree on one answer.
nonisolated struct ShieldSettings: Codable, Equatable {
    var intentions: [Intention] = []
    /// Apps that stay open while everything else is blocked.
    var allowList = FamilyActivitySelection()
    /// The running Blocca ora's end.
    var blockNowEnd: Date?

    static let maxIntentions = 8
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
    /// A field added later to `Intention` must be optional for the same reason.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        intentions = try container.decodeIfPresent([Intention].self, forKey: .intentions) ?? []
        allowList = try container.decodeIfPresent(FamilyActivitySelection.self, forKey: .allowList) ?? FamilyActivitySelection()
        blockNowEnd = try container.decodeIfPresent(Date.self, forKey: .blockNowEnd)
    }

    /// Whether everything but the allowed apps is blocked now. Read from the clock, so a missed
    /// callback cannot leave it wrong.
    func isBlocking(now: Date) -> Bool {
        (blockNowEnd ?? .distantPast) > now
    }

    /// The apps their Intenzione covers now.
    func locked(now: Date, calendar: Calendar = .current) -> Set<ApplicationToken> {
        Set(intentions.filter { $0.isLocked(now: now, calendar: calendar) }.compactMap(\.app))
    }

    /// Adds an Intenzione, up to `maxIntentions`, or replaces the one with the same id.
    mutating func put(_ intention: Intention) {
        if let index = intentions.firstIndex(where: { $0.id == intention.id }) {
            intentions[index] = intention
        } else if intentions.count < Self.maxIntentions {
            intentions.append(intention)
        }
    }

    /// Which Shield `app` shows now. `app` is missing when Screen Time shields a whole category.
    func kind(for app: ApplicationToken?, now: Date) -> ShieldKind {
        let isAllowed = app.map(allowList.applicationTokens.contains) ?? false
        if isBlocking(now: now), !isAllowed { return .session }
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
    /// apps while a block runs.
    func apply(to store: ManagedSettingsStore, now: Date = .now) {
        let locked = locked(now: now)
        store.shield.applications = locked.isEmpty ? nil : locked
        store.shield.applicationCategories = isBlocking(now: now) ? .all(except: allowList.applicationTokens) : nil
    }
}
