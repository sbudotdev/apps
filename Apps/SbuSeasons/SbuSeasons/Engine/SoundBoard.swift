import AVFoundation

/// Gli effetti brevi e il sottofondo in loop. Spenti di default (Impostazioni → Suoni).
/// I file stanno nel bundle col nome dell'effetto (`tonfo.caf`, `vento.m4a`…): se uno manca, quell'effetto
/// non suona e basta.
final class SoundBoard {
    static let shared = SoundBoard()

    private static let extensions = ["caf", "m4a", "wav", "aiff", "mp3"]
    private let bundle: Bundle
    private let settings: () -> SnowSettings
    /// Un lettore per effetto, creato la prima volta che serve (nil = il file non c'è).
    private var players: [String: AVAudioPlayer?] = [:]
    private var ambience: AVAudioPlayer?

    init(bundle: Bundle = .main, settings: @escaping () -> SnowSettings = { Settings.shared.values }) {
        self.bundle = bundle
        self.settings = settings
    }

    private var volume: Float { Float(settings().soundVolume / 100) }

    /// Suona un effetto breve, da capo se stava già suonando. false = suoni spenti o file mancante.
    @discardableResult
    func play(_ name: String) -> Bool {
        guard settings().sounds, let player = player(name) else { return false }
        player.volume = volume
        player.currentTime = 0
        player.play()
        return true
    }

    /// Fa partire il sottofondo in loop (sostituisce quello di prima). false = spenti o file mancante.
    @discardableResult
    func startAmbience(_ name: String) -> Bool {
        stopAmbience()
        guard settings().sounds, let player = player(name) else { return false }
        player.numberOfLoops = -1
        player.volume = volume
        player.play()
        ambience = player
        return true
    }

    func stopAmbience() {
        ambience?.stop()
        ambience = nil
    }

    /// Le Impostazioni sono cambiate: il sottofondo prende il volume nuovo, o tace se i suoni si spengono.
    func settingsChanged() {
        if settings().sounds { ambience?.volume = volume } else { stopAmbience() }
    }

    private func player(_ name: String) -> AVAudioPlayer? {
        if let known = players[name] { return known }
        let url = Self.extensions.lazy.compactMap { self.bundle.url(forResource: name, withExtension: $0) }.first
        let player = url.flatMap { try? AVAudioPlayer(contentsOf: $0) }
        player?.prepareToPlay()
        players[name] = player
        return player
    }
}
