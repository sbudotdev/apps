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

    enum Hat: String, Codable, CaseIterable, Sendable { case none, topHat, beanie }
    enum Scarf: String, Codable, CaseIterable, Sendable { case none, red, green }
    enum Nose: String, Codable, CaseIterable, Sendable { case carrot, coal, none }

    /// Dal basso: pancia, petto, testa.
    var balls: [Size] = [.medium, .medium, .medium]
    var hat = Hat.none
    var scarf = Scarf.none
    var nose = Nose.carrot
    var buttons = true

    /// Le larghezze delle tre palle a taglia media, dal basso (come il pupazzo della 2.0).
    private static let widths: [CGFloat] = [26, 20, 14]
    private static let margin: CGFloat = 2

    private var hatHeight: CGFloat {
        switch hat {
        case .none: 0
        case .topHat: 11
        case .beanie: 8
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
        let width = max(widths.max() ?? 0, head + 16, head * 1.4) + Self.margin * 2
        return CGSize(width: width.rounded(.up), height: (stacked + hatHeight + 1).rounded(.up))
    }
}
