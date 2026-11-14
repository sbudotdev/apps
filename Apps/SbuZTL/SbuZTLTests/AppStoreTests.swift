import Foundation
import Testing
@testable import SbuZTL

struct AppStoreTests {
    /// A file from before `showsParking`, `shows3D` and `speaks` existed.
    private static let oldFile = """
    {"vehicles":[{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","nickname":"Panda","kind":"car","fuel":"petrol","euro":"euro5"}],
     "permits":[],"favorites":[],"recents":[],"hasFinishedIntro":true,"avoidsPaidZones":false,"keepsNorthUp":true}
    """

    @Test("An older file keeps its vehicles and settings, new fields take their defaults")
    func olderFile() throws {
        let url = URL.temporaryDirectory.appendingPathComponent("ztl-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data(Self.oldFile.utf8).write(to: url)

        let store = AppStore(url: url)
        #expect(store.state.vehicles.map(\.nickname) == ["Panda"])
        #expect(store.state.hasFinishedIntro)
        #expect(!store.state.avoidsPaidZones)
        #expect(store.state.keepsNorthUp)
        #expect(store.state.speaks)
        #expect(store.state.shows3D)
        #expect(!store.state.showsParking)
    }

    @Test("An unreadable file is copied aside before it can be overwritten")
    func unreadableFile() throws {
        let url = URL.temporaryDirectory.appendingPathComponent("ztl-\(UUID()).json")
        let copy = url.appendingPathExtension("unreadable")
        defer { [url, copy].forEach { try? FileManager.default.removeItem(at: $0) } }
        try Data("not json".utf8).write(to: url)

        let store = AppStore(url: url)
        #expect(store.state.vehicles.isEmpty)
        #expect(try Data(contentsOf: copy) == Data("not json".utf8))
    }
}
