import Foundation

/// What you have put together so far: the time in a block today and the best day's.
/// Kept apart from `ShieldSettings`, with Foundation only, so the widget reads it without Screen Time.
nonisolated struct Tally: Codable, Equatable {
    /// The day `blockedSeconds` counts.
    var blockedDay: Day?
    /// The finished blocks of `blockedDay`.
    var blockedSeconds: TimeInterval = 0
    /// The running block's start.
    var blockingSince: Date?
    /// The most time blocked in one day.
    var record: TimeInterval = 0

    init() {}

    /// A field missing from an older save takes its default: failing here would wipe everything else.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        blockedDay = try container.decodeIfPresent(Day.self, forKey: .blockedDay)
        blockedSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .blockedSeconds) ?? 0
        blockingSince = try container.decodeIfPresent(Date.self, forKey: .blockingSince)
        record = try container.decodeIfPresent(TimeInterval.self, forKey: .record) ?? 0
    }

    /// The time in a block today, up to `now`.
    func blocked(now: Date, calendar: Calendar = .current) -> TimeInterval {
        let finished = blockedDay == Day(now, calendar: calendar) ? blockedSeconds : 0
        guard let blockingSince else { return finished }
        return finished + now.timeIntervalSince(max(blockingSince, calendar.startOfDay(for: now)))
    }

    /// Brings the count to `now`: called whenever the Shield is applied, with what was just applied.
    /// A day that turned closes at midnight and may become the record.
    mutating func settle(isBlocking: Bool, now: Date, calendar: Calendar = .current) {
        let today = Day(now, calendar: calendar)
        if blockedDay != today {
            let midnight = calendar.startOfDay(for: now)
            if let since = blockingSince, since < midnight {
                blockedSeconds += midnight.timeIntervalSince(since)
                blockingSince = midnight
            }
            record = max(record, blockedSeconds)
            blockedSeconds = 0
            blockedDay = today
        }
        if isBlocking, blockingSince == nil {
            blockingSince = now
        }
        if !isBlocking, let since = blockingSince {
            blockedSeconds += now.timeIntervalSince(since)
            blockingSince = nil
            record = max(record, blockedSeconds)
        }
    }

    static func load(from defaults: UserDefaults) -> Tally {
        defaults.data(forKey: "tally").flatMap { try? JSONDecoder().decode(Tally.self, from: $0) } ?? Tally()
    }

    func save(to defaults: UserDefaults) {
        defaults.set(try? JSONEncoder().encode(self), forKey: "tally")
    }

    /// Loads, changes and saves in one go, as `ShieldSettings.update(in:_:)` does and for the same reason.
    @discardableResult
    static func update(in defaults: UserDefaults, _ change: (inout Tally) -> Void) -> Tally {
        var tally = load(from: defaults)
        change(&tally)
        tally.save(to: defaults)
        return tally
    }
}
