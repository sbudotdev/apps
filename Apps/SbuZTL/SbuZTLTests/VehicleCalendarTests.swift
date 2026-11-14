import Foundation
import Testing
@testable import SbuZTL

struct VehicleCalendarTests {
    @Test("Fourteen days ahead, today first")
    func days() throws {
        let days = VehicleCalendar.days(from: RuleEngineTests.monday)
        #expect(days.count == 14)
        #expect(days.first == Holidays.calendar.startOfDay(for: RuleEngineTests.monday))
    }

    @Test("A day's spans cover midnight to midnight with no gap, and change answer at each joint")
    func spans() {
        let day = Holidays.calendar.startOfDay(for: RuleEngineTests.monday)
        let spans = VehicleCalendar.spans(zone: RuleEngineTests.areaC, vehicle: RuleEngineTests.car(.petrol, .euro5), day: day)
        #expect(spans.first?.startMinute == 0)
        #expect(spans.last?.endMinute == 1440)
        for (a, b) in zip(spans, spans.dropFirst()) {
            #expect(a.endMinute == b.startMinute)
            #expect(a.access != b.access)
        }
        #expect(spans.count > 1) // Area C closes on a weekday: off, then in force, then off
    }
}
