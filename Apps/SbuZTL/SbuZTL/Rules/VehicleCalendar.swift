import Foundation

/// When a vehicle can enter a zone, day by day.
nonisolated enum VehicleCalendar {
    /// The next days, today first.
    static func days(from date: Date, count: Int = 14) -> [Date] {
        let start = Holidays.calendar.startOfDay(for: date)
        return (0..<count).compactMap { Holidays.calendar.date(byAdding: .day, value: $0, to: start) }
    }

    /// Sampled every 30 minutes, the unit of every schedule read so far.
    static func spans(zone: Zone, vehicle: Vehicle, day: Date, permits: [Permit] = []) -> [AccessSpan] {
        var spans: [AccessSpan] = []
        for minute in stride(from: 0, to: 1440, by: 30) {
            let hour = minute / 60
            let moment = Holidays.calendar.date(bySettingHour: hour, minute: minute % 60, second: 0, of: day) ?? day
            let access = RuleEngine.verdict(zone: zone, vehicle: vehicle, at: moment, permits: permits).access
            if let last = spans.last, last.access == access {
                spans[spans.count - 1] = AccessSpan(startMinute: last.startMinute, endMinute: minute + 30, access: access)
            } else {
                spans.append(AccessSpan(startMinute: minute, endMinute: minute + 30, access: access))
            }
        }
        return spans
    }
}
