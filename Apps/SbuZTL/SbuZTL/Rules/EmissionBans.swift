import Foundation

/// When each class is banned, private passenger cars only. Dates from the acts in `RuleSource`, read on 1/11/2026.
nonisolated enum EmissionBans {
    /// `nil` when the act doesn't ban the class. Every case of diesel up to Euro 4 falls by 1/10/2022, with or without a filter.
    static func areaC(fuel: Fuel, euro: EuroClass) -> Date? {
        switch (fuel, euro) {
        case (.petrol, .euro0): day(2019, 2, 25)
        case (.petrol, .euro1): day(2019, 10, 1)
        case (.petrol, .euro2): day(2022, 10, 1)
        case (.petrol, .euro3): day(2024, 10, 1)
        case (.petrol, .euro4): day(2027, 10, 1)
        case (.petrol, .euro5): day(2030, 10, 1)
        case (.diesel, .euro0), (.diesel, .euro1), (.diesel, .euro2), (.diesel, .euro3), (.diesel, .euro4), (.diesel, .euro5): day(2022, 10, 1)
        case (.diesel, .euro6abc): day(2028, 10, 1)
        case (.diesel, .euro6d): day(2029, 10, 1)
        default: nil
        }
    }

    static func areaB(fuel: Fuel, euro: EuroClass) -> Date? {
        switch (fuel, euro) {
        case (.petrol, .euro0): day(2019, 2, 25)
        case (.petrol, .euro1): day(2021, 1, 11)
        case (.petrol, .euro2): day(2022, 10, 1)
        case (.petrol, .euro3): day(2025, 10, 1)
        case (.petrol, .euro4): day(2028, 10, 1)
        case (.diesel, .euro0), (.diesel, .euro1), (.diesel, .euro2), (.diesel, .euro3), (.diesel, .euro4), (.diesel, .euro5): day(2022, 10, 1)
        case (.diesel, .euro6abc): day(2028, 10, 1)
        case (.diesel, .euro6d): day(2030, 10, 1)
        default: nil
        }
    }

    private static func day(_ year: Int, _ month: Int, _ day: Int) -> Date? {
        Holidays.calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
}
