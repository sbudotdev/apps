import Foundation
import Testing
@testable import SbuZTL

struct ReportMailTests {
    @Test func namesTheZoneAndEncodesIt() throws {
        let url = try #require(ReportMail.url(zone: "Area C"))
        #expect(url.scheme == "mailto")
        #expect(url.absoluteString.contains(ReportMail.address))
        #expect(url.absoluteString.contains("Area%20C"))
    }
}
