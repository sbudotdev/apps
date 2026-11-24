@testable import SbuBar
import Foundation
import Testing

struct SmokeTests {
    @Test func bundleIdentifierIsDevSbuBar() {
        #expect(Bundle(identifier: "dev.sbu.bar") != nil)
    }
}
