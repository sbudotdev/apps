import CoreGraphics

/// Com'è fatto un pupazzo: la taglia delle tre palle (dal basso) e i vestiti. Solo dati: si prova senza disegnare
/// e si salva com'è (`KeptToys`). Il disegno lo fa `Snowman`, a partire da `ballFrames` e `size`.
nonisolated struct SnowmanLook: Codable, Hashable, Sendable {
    enum Size: String, Codable, CaseIterable, Sendable {
        case small, medium, large
        var scale: CGFloat {
            switch self {
            case .small: 0.8
            case .medium: 1
            case .large: 1.25
            }
        }
    }

    enum Hat: String, Codable, CaseIterable, Sendable { case none, topHat, beanie, cowboy, party, elf, pirate, crown, antlers }
    enum Scarf: String, Codable, CaseIterable, Sendable { case none, red, green, striped }
    enum Nose: String, Codable, CaseIterable, Sendable { case carrot, coal, none }
    enum Eyes: String, Codable, CaseIterable, Sendable { case coal, stars }

    /// Dal basso: pancia, petto, testa.
    var balls: [Size] = [.medium, .medium, .medium]
    var hat = Hat.none
    var scarf = Scarf.none
    var nose = Nose.carrot
    var buttons = true
    // Il secondo giro di vestiti (SBU-187).
    var eyes = Eyes.coal
    var mittens = false
    var bowTie = false
    var sweater = false
    var cape = false

    init() {}

    /// Un pupazzo salvato prima di un vestito nuovo si apre lo stesso: quello che manca prende il suo predefinito.
    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let base = SnowmanLook()
        balls = try c.decodeIfPresent([Size].self, forKey: .balls) ?? base.balls
        hat = try c.decodeIfPresent(Hat.self, forKey: .hat) ?? base.hat
        scarf = try c.decodeIfPresent(Scarf.self, forKey: .scarf) ?? base.scarf
        nose = try c.decodeIfPresent(Nose.self, forKey: .nose) ?? base.nose
        buttons = try c.decodeIfPresent(Bool.self, forKey: .buttons) ?? base.buttons
        eyes = try c.decodeIfPresent(Eyes.self, forKey: .eyes) ?? base.eyes
        mittens = try c.decodeIfPresent(Bool.self, forKey: .mittens) ?? base.mittens
        bowTie = try c.decodeIfPresent(Bool.self, forKey: .bowTie) ?? base.bowTie
        sweater = try c.decodeIfPresent(Bool.self, forKey: .sweater) ?? base.sweater
        cape = try c.decodeIfPresent(Bool.self, forKey: .cape) ?? base.cape
    }

    /// Le larghezze delle tre palle a taglia media, dal basso (come il pupazzo della 2.0).
    private static let widths: [CGFloat] = [26, 20, 14]
    private static let margin: CGFloat = 2

    private var hatHeight: CGFloat {
        switch hat {
        case .none: 0
        case .topHat: 11
        case .beanie: 8
        case .cowboy, .pirate, .crown: 8
        case .antlers: 10
        case .party: 13
        case .elf: 14
        }
    }

    /// Le tre palle, dal basso, nel disegno (origine in basso a sinistra): un po' schiacciate e un po' l'una dentro l'altra.
    var ballFrames: [CGRect] {
        let widths = zip(Self.widths, balls.count == 3 ? balls : [.medium, .medium, .medium]).map { $0 * $1.scale }
        let center = size.width / 2
        var frames: [CGRect] = []
        var bottom: CGFloat = 0
        for (i, width) in widths.enumerated() {
            let height = i == 2 ? width : width * 0.85
            if i > 0 { bottom -= height * (i == 2 ? 0.2 : 0.3) }
            frames.append(CGRect(x: center - width / 2, y: bottom, width: width, height: height))
            bottom += height
        }
        return frames
    }

    /// Quanto è grande il disegno: largo quanto la palla più larga (o il naso, la falda del cappello), alto fino al cappello.
    var size: CGSize {
        let widths = zip(Self.widths, balls.count == 3 ? balls : [.medium, .medium, .medium]).map { $0 * $1.scale }
        let heights = [widths[0] * 0.85, widths[1] * 0.85, widths[2]]
        let stacked = heights[0] + heights[1] * 0.7 + heights[2] * 0.8
        let head = widths[2]
        // Le muffole stanno in fondo a due rametti, ai lati del petto.
        let arms = mittens ? widths[1] + 22 : 0
        let width = max(widths.max() ?? 0, head + 16, head * 1.6, arms) + Self.margin * 2
        return CGSize(width: width.rounded(.up), height: (stacked + hatHeight + 1).rounded(.up))
    }
}
