@testable import SbuBar
import Foundation
import Testing

struct SettingsStoreTests {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let item = ItemID(bundleID: "com.example.a", name: "A")

    @Test func loadWithoutFilesGivesDefaults() {
        #expect(SettingsStore(directory: directory).load() == Settings())
    }

    @Test func saveThenLoadRoundTrips() throws {
        let store = SettingsStore(directory: directory)
        let settings = Settings(layout: BarLayout(order: [.hidden: [item]]))
        try store.save(settings)
        #expect(store.load() == settings)
    }

    @Test func corruptFileFallsBackToBackup() throws {
        let store = SettingsStore(directory: directory)
        let first = Settings(layout: BarLayout(order: [.hidden: [item]]))
        try store.save(first)
        try store.save(Settings(layout: BarLayout(order: [.shown: [item]])))
        try Data("{".utf8).write(to: directory.appending(path: "settings.json"))
        #expect(store.load() == first)
    }

    @Test func savedFileCarriesTheVersion() throws {
        let store = SettingsStore(directory: directory)
        try store.save(Settings())
        let data = try Data(contentsOf: directory.appending(path: "settings.json"))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["version"] as? Int == Settings.currentVersion)
    }

    @Test func layoutJSONIsKeyedBySectionName() throws {
        let data = try JSONEncoder().encode(BarLayout(order: [.hidden: [item]]))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(json["hidden"] != nil)
    }

    @Test func decodingDropsDuplicatesKeepingTheMostHiddenOccurrence() throws {
        let other = ItemID(bundleID: "com.example.b", name: "B")
        let a = #"{"bundleID":"com.example.a","name":"A"}"#
        let b = #"{"bundleID":"com.example.b","name":"B"}"#
        let json = #"{"shown":[\#(a),\#(b),\#(a)],"hidden":[\#(a)],"alwaysHidden":[\#(b)]}"#
        let layout = try JSONDecoder().decode(BarLayout.self, from: Data(json.utf8))
        #expect(layout.order[.alwaysHidden] == [other])
        #expect(layout.order[.hidden] == [item])
        #expect(layout.order[.shown, default: []].isEmpty)
    }

    @Test func decodingIgnoresUnknownSectionKeys() throws {
        let a = #"{"bundleID":"com.example.a","name":"A"}"#
        let json = #"{"shown":[\#(a)],"future":[\#(a)]}"#
        let layout = try JSONDecoder().decode(BarLayout.self, from: Data(json.utf8))
        #expect(layout.order == [.shown: [item]])
    }
}
