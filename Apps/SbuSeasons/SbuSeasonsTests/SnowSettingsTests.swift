import Foundation
import Testing
@testable import SbuSeasons

struct SnowSettingsTests {
    private func json(_ object: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object)
    }

    @Test func nothingSavedGivesTheDefaults() {
        #expect(SnowSettings(saved: nil) == SnowSettings())
    }

    @Test func savedValuesWinAndMissingOnesKeepTheirDefault() throws {
        let settings = SnowSettings(saved: try json(["wind": 40.0, "accumulate": false]))
        #expect(settings.wind == 40)
        #expect(settings.accumulate == false)
        #expect(settings.flakeCount == SnowSettings().flakeCount)
    }

    @Test func oneBadValueDoesNotWipeTheOthers() throws {
        let settings = SnowSettings(saved: try json(["wind": "forte", "maxPile": 30.0]))
        #expect(settings.wind == SnowSettings().wind)
        #expect(settings.maxPile == 30)
    }

    @Test func unreadableDataGivesTheDefaults() {
        #expect(SnowSettings(saved: Data("non è json".utf8)) == SnowSettings())
    }
}
