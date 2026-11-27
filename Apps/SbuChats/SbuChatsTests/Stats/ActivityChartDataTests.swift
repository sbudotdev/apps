import Foundation
import Testing
@testable import SbuChats

struct ActivityChartDataTests {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome") ?? .gmt
        return calendar
    }()

    @Test func everyHourHasASlotEvenWithoutMessages() {
        let data = ActivityChartData(axis: .hour, points: [ActivityPoint(slot: 21, series: .you, count: 4)],
                                     calendar: Self.calendar, locale: Locale(identifier: "it_IT"))
        #expect(data.slots.count == 24)
        #expect(data.slots[21].label == "21")
        #expect(data.bars.count == 24)
        #expect(data.peak?.id == 21)
    }

    @Test func hoursFollowTheLocaleClock() {
        let data = ActivityChartData(axis: .hour, points: [], calendar: Self.calendar, locale: Locale(identifier: "en_US"))
        #expect(data.slots[21].label.contains("9"))
        #expect(data.slots[21].label.uppercased().contains("PM"))
    }

    @Test(arguments: [("it_IT", 2), ("en_US", 1)])
    func weekdaysStartOnTheLocalesFirstDay(identifier: String, firstWeekday: Int) {
        var calendar = Self.calendar
        calendar.locale = Locale(identifier: identifier)
        calendar.firstWeekday = firstWeekday
        let data = ActivityChartData(axis: .weekday, points: [], calendar: calendar, locale: Locale(identifier: identifier))
        #expect(data.slots.first?.id == firstWeekday)
        #expect(data.slots.count == 7)
    }

    @Test func monthsFillTheGapsBetweenFirstAndLast() {
        let points = [ActivityPoint(slot: 2024 * 12 + 10, series: .others, count: 3), ActivityPoint(slot: 2025 * 12 + 1, series: .you, count: 5)]
        let data = ActivityChartData(axis: .month, points: points, calendar: Self.calendar, locale: Locale(identifier: "it_IT"))
        #expect(data.slots.count == 4) // nov, dic, gen, feb
        #expect(data.bars.count == 8) // two series in every slot
        #expect(data.total(in: data.slots[3]) == 5)
        #expect(data.count(in: data.slots[0], series: .others) == 3)
        #expect(data.peak == data.slots[3])
    }

    @Test func anEmptyChartHasNoPeak() {
        #expect(ActivityChartData(axis: .year, points: []).peak == nil)
    }

    @Test(arguments: [("it_IT", false, ["3", "6", "9", "12", "15", "18", "21"]),
                      ("it_IT", true, ["6", "12", "18"]),
                      ("en_US", false, ["4 AM", "8 AM", "12 PM", "4 PM", "8 PM"]),
                      ("en_US", true, ["8 AM", "4 PM"])])
    func hourAxisShowsFewLabelsAndWiderOnesFurtherApart(identifier: String, isLarge: Bool, expected: [String]) {
        let data = ActivityChartData(axis: .hour, points: [], calendar: Self.calendar, locale: Locale(identifier: identifier))
        let labels = data.axisLabels(axis: .hour, isLarge: isLarge)
        // The 12-hour clock puts a narrow space before AM/PM: compare letters and digits only.
        #expect(labels.map { $0.filter { $0.isLetter || $0.isNumber } } == expected.map { $0.filter { $0.isLetter || $0.isNumber } })
    }

    @Test func monthAxisSkipsTheEdges() {
        let points = (0 ..< 12).map { ActivityPoint(slot: 2024 * 12 + $0, series: .you, count: 1) }
        let data = ActivityChartData(axis: .month, points: points, calendar: Self.calendar, locale: Locale(identifier: "it_IT"))
        let labels = data.axisLabels(axis: .month, isLarge: false)
        #expect(!labels.contains(data.slots[0].label))
        #expect(!labels.contains(data.slots[11].label))
        #expect(data.axisLabels(axis: .month, isLarge: true) == [data.slots[6].label])
    }
}
