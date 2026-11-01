import Foundation

/// Rome's emission ring: bans by class on top of the ZTLs (Roma Servizi per la Mobilità, updated 7/10/2026).
nonisolated enum FasciaVerde {
    static let schedule = Schedule(windows: [ScheduleWindow(days: ScheduleWindow.mondayToSaturday, start: 0, end: 1440)], holidays: .excludedMidweek)
    /// The extension stated by Roma Capitale ends here.
    static let validUntil = DateComponents(year: 2027, month: 10, day: 31)
    /// Vehicles and exceptions come from an ordinance each time.
    static let ecoSundays = [(2026, 11, 15), (2026, 12, 6), (2027, 1, 24), (2027, 2, 21), (2027, 3, 21)]

    static func isEcoSundayBand(_ date: Date) -> Bool {
        let c = Holidays.calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard ecoSundays.contains(where: { $0.0 == c.year && $0.1 == c.month && $0.2 == c.day }) else { return false }
        let minute = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        return (450..<750).contains(minute) || (990..<1230).contains(minute)
    }

    static func isExpired(_ date: Date) -> Bool {
        guard let last = Holidays.calendar.date(from: validUntil),
              let end = Holidays.calendar.date(byAdding: .day, value: 1, to: last) else { return true }
        return date >= end
    }

    /// `nil` when the page doesn't settle this vehicle.
    static func isBanned(_ vehicle: Vehicle) -> Bool? {
        guard let euro = vehicle.euro else { return nil }
        switch vehicle.kind {
        case .moped: return nil
        case .motorcycle: return [.euro0, .euro1].contains(euro)
        case .car:
            switch vehicle.fuel {
            case .petrol: return [.euro0, .euro1, .euro2].contains(euro)
            case .diesel: return [.euro0, .euro1, .euro2, .euro3].contains(euro)
            // Up to Euro 2 there's an exception by the date of the registration document, which the app doesn't know.
            case .gas: return [.euro0, .euro1, .euro2].contains(euro) ? nil : false
            case .hybrid, .electric: return nil
            }
        }
    }
}
