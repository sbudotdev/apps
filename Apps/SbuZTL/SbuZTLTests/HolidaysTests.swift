import Foundation
import Testing
@testable import SbuZTL

struct HolidaysTests {
    @Test("Easter Sunday", arguments: [(2024, 3, 31), (2026, 4, 5), (2027, 3, 28), (2030, 4, 21)])
    func easter(year: Int, month: Int, day: Int) {
        let easter = Holidays.easterSunday(year: year)
        #expect(easter.month == month)
        #expect(easter.day == day)
    }

    @Test("National holidays, Easter Monday included")
    func national() {
        #expect(Holidays.isNational(RuleEngineTests.moment(2026, 6, 2, 9)))
        #expect(Holidays.isNational(RuleEngineTests.moment(2026, 4, 6, 9)))
        #expect(!Holidays.isNational(RuleEngineTests.moment(2026, 4, 7, 9)))
    }
}
