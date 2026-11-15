import Foundation
import Testing
@testable import SbuSeasons

/// SbuKit non c'è su macOS: i valori del Quaderno usati dall'app sono copiati in `Quaderno`.
/// Questo test li confronta con `Design/tokens.json`, così una modifica ai token non passa inosservata.
struct QuadernoTokensTests {
    private static let tokens: [String: Any] = {
        let url = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appending(path: "../../../Design/tokens.json")
        let data = (try? Data(contentsOf: url)) ?? Data()
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }()

    /// Ogni `{ "name", "value" }` di ogni gruppo di `tokens.json`, colori compresi.
    private static let values: [String: Any] = {
        var all: [String: Any] = [:]
        for case let group as [String: Any] in tokens.values {
            for case let token as [String: Any] in group["tokens"] as? [Any] ?? [] {
                if let name = token["name"] as? String { all[name] = token["value"] }
            }
        }
        return all
    }()

    private static func hex(_ string: String?) -> UInt32? {
        string.flatMap { UInt32($0.dropFirst(), radix: 16) }
    }

    @Test(arguments: Quaderno.colors)
    func colorMatchesTheToken(_ tinta: Tinta) throws {
        let value = try #require(Self.values[tinta.token] as? [String: String], "\(tinta.token) manca in tokens.json")
        #expect(Self.hex(value["light"]) == tinta.light)
        #expect(Self.hex(value["dark"]) == tinta.dark)
    }

    @Test(arguments: Quaderno.metrics.keys.sorted())
    func metricMatchesTheToken(_ name: String) throws {
        let raw = try #require(Self.values[name] as? String, "\(name) manca in tokens.json")
        let number = try #require(Double(raw.prefix { $0.isNumber || $0 == "." }))
        let expected = raw.hasSuffix("%") ? number / 100 : number
        #expect(Double(try #require(Quaderno.metrics[name])) == expected)
    }

    @Test func bundledFontsAreRegistered() {
        #expect(Quaderno.fontsAreRegistered)
    }
}

extension Tinta: @retroactive CustomTestStringConvertible {
    public var testDescription: String { token }
}
