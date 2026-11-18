import AVFoundation

/// Gli effetti brevi e il sottofondo in loop. Spenti di default (Impostazioni → Suoni).
/// I file stanno nel bundle col nome dell'effetto (`tonfo.caf`, `vento.m4a`…), oppure numerati
/// (`pallina-1`, `pallina-2`…): allora ogni volta ne suona uno a caso. Se manca, quell'effetto non suona e basta.
final class SoundBoard {
    static let shared = SoundBoard()

    private static let extensions = ["caf", "m4a", "wav", "aiff", "mp3"]
    private let bundle: Bundle
    private let settings: () -> SnowSettings
    /// I lettori di un effetto, creati la prima volta che serve (vuoto = il file non c'è).
    private var players: [String: [AVAudioPlayer]] = [:]
    private var ambience: AVAudioPlayer?
    /// Il sottofondo della stagione: suona quando i suoni sono accesi.
    private var wantedAmbience: String?

    init(bundle: Bundle = .main, settings: @escaping () -> SnowSettings = { Settings.shared.values }) {
        self.bundle = bundle
        self.settings = settings
    }

    private var volume: Float { Float(settings().soundVolume / 100) }

    /// Suona un effetto breve, da capo se stava già suonando. false = suoni spenti o file mancante.
    @discardableResult
    func play(_ name: String) -> Bool {
        guard settings().sounds, let player = players(name).randomElement() else { return false }
        player.volume = volume
        player.currentTime = 0
        player.play()
        return true
    }

    /// Quanti file ci sono per questo effetto.
    func variants(_ name: String) -> Int { players(name).count }

    /// Fa partire il sottofondo in loop (sostituisce quello di prima). false = spenti o file mancante.
    @discardableResult
    func startAmbience(_ name: String) -> Bool {
        stopAmbience()
        guard settings().sounds, let player = players(name).first else { return false }
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

    var isPlayingAmbience: Bool { ambience != nil }

    /// Il sottofondo da tenere (nil = silenzio): parte subito se i suoni sono accesi, se no quando si accendono.
    func setAmbience(_ name: String?) {
        guard name != wantedAmbience || ambience == nil else { return }
        wantedAmbience = name
        if let name { startAmbience(name) } else { stopAmbience() }
    }

    /// Le Impostazioni sono cambiate: il sottofondo prende il volume nuovo, parte, o tace se i suoni si spengono.
    func settingsChanged() {
        guard settings().sounds else { return stopAmbience() }
        if let ambience { ambience.volume = volume } else if let wantedAmbience { startAmbience(wantedAmbience) }
    }

    private func players(_ name: String) -> [AVAudioPlayer] {
        if let known = players[name] { return known }
        func url(_ file: String) -> URL? {
            Self.extensions.lazy.compactMap { self.bundle.url(forResource: file, withExtension: $0) }.first
        }
        var urls = url(name).map { [$0] } ?? []
        if urls.isEmpty {
            while let next = url("\(name)-\(urls.count + 1)") { urls.append(next) }
        }
        let found = urls.compactMap { try? AVAudioPlayer(contentsOf: $0) }
        found.forEach { $0.prepareToPlay() }
        players[name] = found
        return found
    }
}
