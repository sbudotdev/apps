import Foundation
import Testing
@testable import SbuSeasons

/// I suoni: spenti di default, e un file che manca non suona e non rompe niente.
@MainActor
struct SoundBoardTests {
    /// Una cartella con un breve WAV muto, letta come bundle.
    private static func bundle(with name: String) throws -> Bundle {
        let dir = FileManager.default.temporaryDirectory.appending(path: "sounds-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try silentWAV().write(to: dir.appending(path: "\(name).wav"))
        return try #require(Bundle(url: dir))
    }

    /// 0,1 s di silenzio, 8 kHz, 8 bit mono.
    private static func silentWAV() -> Data {
        let samples = 800
        var data = Data()
        func append(_ s: String) { data.append(contentsOf: Array(s.utf8)) }
        func append32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        func append16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        append("RIFF"); append32(UInt32(36 + samples)); append("WAVE")
        append("fmt "); append32(16); append16(1); append16(1); append32(8000); append32(8000); append16(1); append16(8)
        append("data"); append32(UInt32(samples)); data.append(contentsOf: [UInt8](repeating: 128, count: samples))
        return data
    }

    @Test func soundsAreOffByDefault() {
        #expect(SnowSettings().sounds == false)
    }

    @Test func offMeansSilent() throws {
        let board = SoundBoard(bundle: try Self.bundle(with: "tonfo"), settings: { SnowSettings() })
        #expect(!board.play("tonfo"))
    }

    @Test func onPlaysAFileThatIsThere() throws {
        var on = SnowSettings()
        on.sounds = true
        let board = SoundBoard(bundle: try Self.bundle(with: "tonfo"), settings: { on })
        #expect(board.play("tonfo"))
    }

    @Test func aMissingFileIsSilentAndHarmless() throws {
        var on = SnowSettings()
        on.sounds = true
        let board = SoundBoard(bundle: try Self.bundle(with: "tonfo"), settings: { on })
        #expect(!board.play("campanelli"))
        #expect(!board.startAmbience("vento"))
        board.stopAmbience()
    }

    @Test func theAmbienceLoops() throws {
        var on = SnowSettings()
        on.sounds = true
        let board = SoundBoard(bundle: try Self.bundle(with: "vento"), settings: { on })
        #expect(board.startAmbience("vento"))
        board.stopAmbience()
    }
}
