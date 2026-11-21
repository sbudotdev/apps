import CoreGraphics
import Foundation
import Testing
@testable import SbuSeasons

/// Un oggetto dentro un file `.sbuseasons` (SBU-200): va e torna uguale, e un file che arriva da fuori non è fidato.
/// Troppo grande, rotto, di una versione più nuova o con valori fuori misura: o non si apre o torna nei limiti.
struct ToyFileTests {
    private func decode(_ json: String) throws -> ToyFile {
        try ToyFile(data: Data(json.utf8))
    }

    private func roundTrip(_ file: ToyFile) throws -> ToyFile {
        try ToyFile(data: file.data())
    }

    // MARK: - Va e torna

    @Test func aDressedSnowmanComesBackTheSame() throws {
        var look = SnowmanLook()
        look.balls = [.large, .small, .medium]
        look.hat = .crown
        look.scarf = .striped
        look.eyes = .stars
        look.cape = true
        #expect(try roundTrip(.snowman(look)) == .snowman(look))
    }

    @Test func aDecoratedTreeComesBackTheSame() throws {
        var look = TreeLook()
        look.hang(at: CGPoint(x: 0, y: 30))
        look.hanging = .star
        look.hang(at: CGPoint(x: 0, y: 70))
        look.grow(by: 1.5)
        look.resize(0, by: 1.4)
        #expect(try roundTrip(.tree(look)) == .tree(look))
    }

    @Test func aDeskDecorationLosesItsScreenAndPlace() throws {
        let item = DeskItem(kind: .penguin, screen: "Studio Display", center: CGPoint(x: 900, y: 500), scale: 1.5, rotation: 0.3)
        let back = try roundTrip(.decoration(item))
        guard case .decoration(let received) = back else { Issue.record("non è una decorazione"); return }
        #expect(received.kind == .penguin && received.scale == 1.5 && received.rotation == 0.3)
        #expect(received.screen.isEmpty, "il nome dello schermo di chi manda non viaggia")
        #expect(received.center == .zero)
        let json = try #require(String(data: ToyFile.decoration(item).data(), encoding: .utf8))
        #expect(!json.contains("Studio Display") && !json.contains(item.id.uuidString))
    }

    @Test func lightsKeepTheirLengthAndSlope() throws {
        let item = DeskItem(kind: .lights, screen: "A", start: CGPoint(x: 100, y: 300), end: CGPoint(x: 400, y: 340))
        guard case .decoration(let received) = try roundTrip(.decoration(item)) else { Issue.record(); return }
        #expect(received.end.x - received.start.x == 300)
        #expect(received.end.y - received.start.y == 40)
        #expect(received.center == .zero)
    }

    @Test func theFileSaysWhatItIsAndItsVersion() throws {
        let object = try JSONSerialization.jsonObject(with: ToyFile.snowman(SnowmanLook()).data()) as? [String: Any]
        #expect(object?["format"] as? String == ToyFile.format)
        #expect(object?["version"] as? Int == ToyFile.version)
    }

    // MARK: - File che non si aprono

    @Test(arguments: [
        "",
        "null",
        "[]",
        "\"pupazzo\"",
        "{",
        #"{"format":"sbuseasons","version":1}"#,                                                  // vuoto
        #"{"version":1,"snowman":{}}"#,                                                          // senza formato
        #"{"format":"altro","version":1,"snowman":{}}"#,                                         // formato di qualcun altro
        #"{"format":"sbuseasons","snowman":{}}"#,                                                // senza versione
        #"{"format":"sbuseasons","version":0,"snowman":{}}"#,
        #"{"format":"sbuseasons","version":"1","snowman":{}}"#,
        #"{"format":"sbuseasons","version":1,"snowman":{},"tree":{}}"#,                          // due oggetti
        #"{"format":"sbuseasons","version":1,"snowman":{"hat":"bazooka"}}"#,                     // vestito che non c'è
        #"{"format":"sbuseasons","version":1,"snowman":{"balls":"grandi"}}"#,
        #"{"format":"sbuseasons","version":1,"tree":{"growth":"alto"}}"#,
        #"{"format":"sbuseasons","version":1,"tree":{"growth":1,"hanging":"bauble","decorations":[{"kind":"bomb","position":[0,30],"scale":1,"rotation":0,"color":0}]}}"#,
        #"{"format":"sbuseasons","version":1,"tree":{"growth":1,"hanging":"bauble","decorations":[{"kind":"bauble","position":[0],"scale":1,"rotation":0,"color":0}]}}"#,
        #"{"format":"sbuseasons","version":1,"tree":{"growth":1,"hanging":"bauble"}}"#,          // senza decorazioni
        #"{"format":"sbuseasons","version":1,"decoration":{"kind":"lights"}}"#,                  // mancano le misure
        #"{"format":"sbuseasons","version":1,"decoration":{"kind":"rocket","scale":1,"rotation":0,"span":[0,0]}}"#,
        #"{"format":"sbuseasons","version":1,"decoration":{"kind":"candle","scale":1e999,"rotation":0,"span":[0,0]}}"#,
    ])
    func aBrokenFileDoesNotOpen(_ json: String) {
        #expect(throws: ToyFile.ReadError.unreadable) { try decode(json) }
    }

    @Test func deeplyNestedJSONDoesNotOpen() {
        let depth = Tuning.toyFileMaxBytes / 2 - 64
        let json = #"{"format":"sbuseasons","version":1,"snowman":{"balls":"# + String(repeating: "[", count: depth)
            + String(repeating: "]", count: depth) + "}}"
        #expect(throws: ToyFile.ReadError.unreadable) { try decode(json) }
    }

    @Test func aFileFromANewerVersionSaysSo() {
        #expect(throws: ToyFile.ReadError.newerVersion) {
            try decode(#"{"format":"sbuseasons","version":99,"snowman":{}}"#)
        }
    }

    @Test func aFileThatIsTooBigIsNotRead() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let big = folder.appending(path: "Grande.sbuseasons")
        let padding = String(repeating: " ", count: Tuning.toyFileMaxBytes)
        try Data((#"{"format":"sbuseasons","version":1,"snowman":{}}"# + padding).utf8).write(to: big)
        #expect(throws: ToyFile.ReadError.tooLarge) { try ToyFile(contentsOf: big) }
    }

    @Test func aFolderOrAMissingFileIsNotRead() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "\(UUID().uuidString).sbuseasons")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        #expect(throws: ToyFile.ReadError.unreadable) { try ToyFile(contentsOf: folder) }
        #expect(throws: ToyFile.ReadError.unreadable) { try ToyFile(contentsOf: folder.appending(path: "nessuno.sbuseasons")) }
        #expect(throws: ToyFile.ReadError.unreadable) { try ToyFile(contentsOf: URL(string: "https://sbu.dev/x.sbuseasons")!) }
    }

    @Test func aFileWrittenToDiskOpens() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let url = try ToyFile.snowman(SnowmanLook()).write(in: folder)
        #expect(url.pathExtension == ToyFile.fileExtension)
        #expect(try ToyFile(contentsOf: url) == .snowman(SnowmanLook()))
    }

    // MARK: - Valori fuori misura: tornano nei limiti

    @Test func aSnowmanWithTheWrongNumberOfBallsGetsThree() throws {
        let many = try decode(#"{"format":"sbuseasons","version":1,"snowman":{"balls":["large","large","large","large","large"]}}"#)
        guard case .snowman(let look) = many else { Issue.record(); return }
        #expect(look.balls == [.large, .large, .large])
        let one = try decode(#"{"format":"sbuseasons","version":1,"snowman":{"balls":["small"]}}"#)
        guard case .snowman(let short) = one else { Issue.record(); return }
        #expect(short.balls == [.small, .medium, .medium])
    }

    @Test func aGiantTreeIsCutDownToSize() throws {
        let decorations = (0..<500).map { _ in #"{"kind":"bauble","position":[0,30],"scale":80,"rotation":1e300,"color":-7}"# }
        let toppers = #"{"kind":"star","position":[3,3],"scale":1,"rotation":0,"color":0},{"kind":"angel","position":[0,0],"scale":1,"rotation":0,"color":0}"#
        let json = #"{"format":"sbuseasons","version":1,"tree":{"growth":1e300,"hanging":"lights","decorations":["#
            + decorations.joined(separator: ",") + "," + toppers + "]}}"
        guard case .tree(let look) = try decode(json) else { Issue.record(); return }
        #expect(look.growth == Tuning.treeGrowth.upperBound)
        #expect(look.decorations.filter { $0.kind.isTopper }.count == 1, "una sola cima")
        #expect(look.decorations.last?.kind == .angel && look.decorations.last?.position == TreeLook.tip)
        #expect(look.decorations.count <= Tuning.maxDecorations + 1)
        let bauble = try #require(look.decorations.first)
        #expect(bauble.scale == Tuning.decorationScale.upperBound)
        #expect(abs(bauble.rotation) <= 2 * .pi)
        #expect((0..<TreeLook.colorCount).contains(bauble.color))
    }

    /// Il rettangolo della chioma non basta: gli angoli in alto sono fuori dal triangolo dei rami (SBU-205).
    @Test(arguments: [CGPoint(x: 99999, y: -5000), CGPoint(x: 28, y: 70), CGPoint(x: -29, y: 60), CGPoint(x: 0, y: 5)])
    func aDecorationOffTheBranchesIsDropped(_ point: CGPoint) throws {
        var onBranch = TreeLook()
        onBranch.hang(at: CGPoint(x: 0, y: 30))
        var look = onBranch
        look.decorations.append(Decoration(kind: .bauble, position: point))
        #expect(try roundTrip(.tree(look)) == .tree(onBranch))
    }

    @Test func aTinyTreeGrowsBackToTheSmallest() throws {
        guard case .tree(let look) = try decode(#"{"format":"sbuseasons","version":1,"tree":{"growth":-3,"hanging":"bauble","decorations":[]}}"#) else { Issue.record(); return }
        #expect(look.growth == Tuning.treeGrowth.lowerBound)
    }

    @Test func aDecorationOutOfRangeIsBroughtBack() throws {
        let json = #"{"format":"sbuseasons","version":1,"decoration":{"kind":"lights","scale":-4,"rotation":2,"span":[1e9,-1e9]}}"#
        guard case .decoration(let item) = try decode(json) else { Issue.record(); return }
        #expect(item.scale == Tuning.deskScale.lowerBound)
        #expect(item.rotation == 0, "le luci non si girano")
        #expect(item.end.x - item.start.x <= Tuning.toyFileMaxLightsSpan)
        #expect(abs(item.end.y - item.start.y) <= Tuning.toyFileMaxLightsSpan)
    }
}
