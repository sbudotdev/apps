import Foundation

/// What you have put together so far: the time in a block today and the best day's, the Serie,
/// the points and the Missione del giorno.
/// Kept apart from `ShieldSettings`, with Foundation only, so the widget reads it without Screen Time.
///
/// The Serie and the points are worked out from the days marked here, never stored: no job has
/// to close a day, so they are right even if the app stayed closed.
nonisolated struct Tally: Codable, Equatable {
    /// The day `blockedSeconds` counts.
    var blockedDay: Day?
    /// The finished blocks of `blockedDay`.
    var blockedSeconds: TimeInterval = 0
    /// The running block's start.
    var blockingSince: Date?
    /// The most time blocked in one day.
    var record: TimeInterval = 0

    /// The day the count began: Screen Time was first allowed.
    var firstDay: Day?
    /// Days an Intenzione went beyond its openings.
    var exceededDays: Set<Day> = []
    /// Days the Obiettivo giornaliero was reached.
    var overGoalDays: Set<Day> = []
    /// The points of the finished blocks.
    var blockXP = 0
    /// The blocks already paid on `rewardedDay`: a Sessione's id, or Blocca ora with its end.
    var rewardedDay: Day?
    var rewarded: Set<String> = []
    var questDay: Day?
    var questDone: Set<QuestTask> = []

    /// The points of a finished day under the Obiettivo giornaliero.
    static let dayXP = 75
    /// The Home Screen widget that shows the Serie: whoever changes it asks for a reload by this name.
    static let widgetKind = "dev.sbu.social.streak"

    init() {}

    /// A field missing from an older save takes its default: failing here would wipe everything else.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        blockedDay = try container.decodeIfPresent(Day.self, forKey: .blockedDay)
        blockedSeconds = try container.decodeIfPresent(TimeInterval.self, forKey: .blockedSeconds) ?? 0
        blockingSince = try container.decodeIfPresent(Date.self, forKey: .blockingSince)
        record = try container.decodeIfPresent(TimeInterval.self, forKey: .record) ?? 0
        firstDay = try container.decodeIfPresent(Day.self, forKey: .firstDay)
        exceededDays = try container.decodeIfPresent(Set<Day>.self, forKey: .exceededDays) ?? []
        overGoalDays = try container.decodeIfPresent(Set<Day>.self, forKey: .overGoalDays) ?? []
        blockXP = try container.decodeIfPresent(Int.self, forKey: .blockXP) ?? 0
        rewardedDay = try container.decodeIfPresent(Day.self, forKey: .rewardedDay)
        rewarded = try container.decodeIfPresent(Set<String>.self, forKey: .rewarded) ?? []
        questDay = try container.decodeIfPresent(Day.self, forKey: .questDay)
        questDone = try container.decodeIfPresent(Set<QuestTask>.self, forKey: .questDone) ?? []
    }

    // MARK: Time in a block

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

    mutating func resetRecord() {
        record = 0
    }

    // MARK: Serie

    private var brokenDays: Set<Day> {
        exceededDays.union(overGoalDays)
    }

    /// Starts the count on `day`, once.
    mutating func begin(on day: Day) {
        if firstDay == nil { firstDay = day }
    }

    mutating func markExceeded(on day: Day) {
        exceededDays.insert(day)
    }

    mutating func markOverGoal(on day: Day) {
        overGoalDays.insert(day)
    }

    /// Whether `day` held: from the first day to today, with nothing broken.
    func isKept(_ day: Day, today: Day) -> Bool {
        guard let firstDay else { return false }
        return day.ordinal >= firstDay.ordinal && day.ordinal <= today.ordinal && !brokenDays.contains(day)
    }

    /// The days in a row that held, up to today, which counts while it holds.
    func streak(on today: Day) -> Int {
        guard let firstDay, !brokenDays.contains(today) else { return 0 }
        let afterLastBroken = brokenDays.map(\.ordinal).filter { $0 < today.ordinal }.max().map { $0 + 1 }
        return max(today.ordinal - max(firstDay.ordinal, afterLastBroken ?? firstDay.ordinal) + 1, 0)
    }

    /// Takes back the most recent broken day.
    mutating func restoreStreak() {
        guard let last = brokenDays.max(by: { $0.ordinal < $1.ordinal }) else { return }
        exceededDays.remove(last)
        overGoalDays.remove(last)
    }

    // MARK: Punti

    /// The points so far: the finished blocks, and every finished day under the Obiettivo giornaliero.
    func xp(on today: Day) -> Int {
        guard let firstDay else { return blockXP }
        let finishedDays = max(today.ordinal - firstDay.ordinal, 0)
        let overGoal = overGoalDays.count { $0.ordinal >= firstDay.ordinal && $0.ordinal < today.ordinal }
        return blockXP + Self.dayXP * (finishedDays - overGoal)
    }

    /// Pays a finished block once a day, by `key`, and ticks the quest's block task.
    mutating func completeBlock(_ key: String, xp: Int, on day: Day) {
        if rewardedDay != day {
            rewardedDay = day
            rewarded = []
        }
        guard rewarded.insert(key).inserted else { return }
        blockXP += xp
        complete(.block, on: day)
    }

    // MARK: Missione del giorno

    /// The tasks done on `day`: yesterday's are gone.
    func quest(on day: Day) -> Set<QuestTask> {
        questDay == day ? questDone : []
    }

    mutating func complete(_ task: QuestTask, on day: Day) {
        if questDay != day {
            questDay = day
            questDone = []
        }
        questDone.insert(task)
    }

    // MARK: Saving

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
