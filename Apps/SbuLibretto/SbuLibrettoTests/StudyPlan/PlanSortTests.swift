import Foundation
import Testing
@testable import SbuLibretto

struct PlanSortTests {
    static func english(_ resource: LocalizedStringResource) -> String {
        var resource = resource
        resource.locale = Locale(identifier: "en")
        return String(localized: resource)
    }

    @Test(arguments: [(PlanSort.date, "Date"), (.grade, "Grade"), (.credits, "Credits")])
    func segmentLabelsAreCapitalizedInEnglish(sort: PlanSort, label: String) {
        #expect(Self.english(sort.title) == label)
    }

    @Test func creditsUnitStaysLowercaseInEnglish() {
        #expect(Self.english("CFU") == "credits")
    }

    @Test func creditsSegmentStaysCFUInItalian() {
        var resource = PlanSort.credits.title
        resource.locale = Locale(identifier: "it")
        #expect(String(localized: resource) == "CFU")
    }
}
