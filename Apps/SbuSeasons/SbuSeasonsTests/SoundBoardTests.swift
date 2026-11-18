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

/// Più file per lo stesso effetto (`pallina-1`, `pallina-2`…) e il sottofondo che segue la stagione.
@MainActor
struct SoundVariantsTests {
    private static func bundle(with names: [String]) throws -> Bundle {
        let dir = FileManager.default.temporaryDirectory.appending(path: "sounds-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let wav = try Data(contentsOf: #require(Bundle.main.url(forResource: "pallina-1", withExtension: "wav")))
        for name in names { try wav.write(to: dir.appending(path: "\(name).wav")) }
        return try #require(Bundle(url: dir))
    }

    private static var on: SnowSettings { var s = SnowSettings(); s.sounds = true; return s }

    @Test func numberedFilesPlayUnderOneName() throws {
        let board = SoundBoard(bundle: try Self.bundle(with: ["pallina-1", "pallina-2", "pallina-3"]), settings: { Self.on })
        #expect(board.play("pallina"))
        #expect(board.variants("pallina") == 3)
    }

    @Test func theAmbienceStartsWhenSoundsAreTurnedOn() throws {
        var settings = SnowSettings()
        let board = SoundBoard(bundle: try Self.bundle(with: ["vento"]), settings: { settings })
        board.setAmbience("vento")
        #expect(!board.isPlayingAmbience)
        settings.sounds = true
        board.settingsChanged()
        #expect(board.isPlayingAmbience)
        board.setAmbience(nil)
        #expect(!board.isPlayingAmbience)
    }

    @Test func seasonsHaveTheirAmbience() {
        #expect(Snow().ambience == "vento")
        #expect(Rain().ambience == "pioggia")
        #expect(Storm().ambience == "pioggia")
        #expect(Fireflies().ambience == nil)
    }

    @Test func everySoundTheAppPlaysIsInTheBundle() {
        let board = SoundBoard(bundle: .main, settings: { Self.on })
        for name in ["palla-di-vetro", "pupazzo", "spazzaneve", "slittino", "funivia", "pallina", "babbo-natale",
                     "regalo", "omino", "tuono", "camino", "lanterna", "passo-neve", "palla-di-neve-lancio",
                     "palla-di-neve-colpo", "vento", "pioggia"] {
            #expect(board.variants(name) > 0, "manca \(name)")
        }
    }
}
