import CoreGraphics
import Foundation

/// Una decorazione libera sulla scrivania («Decora», SBU-187): dove sta, quanto è grande e girata, su quale schermo.
/// Le coordinate sono quelle dello schermo, dall'angolo in basso a sinistra. Le luci invece hanno due estremità libere
/// (`start`, `end`) e il centro che pende. Solo dati: si prova senza disegnare e si salva in `KeptToys`.
///
/// La regola dell'anno: restano tutto l'anno e con ogni effetto, finché non le togli. Le hai messe tu sulla scrivania;
/// alberi e pupazzi invece sono neve, e fuori dall'inverno si sciolgono.
nonisolated struct DeskItem: Codable, Equatable, Sendable, Identifiable {
    enum Kind: String, Codable, CaseIterable, Sendable {
        case lights, garland, stocking, candle, bonfire, penguin, snowGlobe

        var title: String {
            switch self {
            case .lights: String(localized: "Luci da appendere")
            case .garland: String(localized: "Ghirlanda")
            case .stocking: String(localized: "Calza")
            case .candle: String(localized: "Candela")
            case .bonfire: String(localized: "Falò")
            case .penguin: String(localized: "Pinguino")
            case .snowGlobe: String(localized: "Palla di vetro")
            }
        }

        /// Quanto è grande a grandezza 1 (pt). Le luci no: le misurano le due estremità.
        var size: CGSize {
            switch self {
            case .lights: CGSize(width: 220, height: 40)
            case .garland: CGSize(width: 140, height: 44)
            case .stocking: CGSize(width: 40, height: 58)
            case .candle: CGSize(width: 26, height: 64)
            case .bonfire: CGSize(width: 66, height: 60)
            case .penguin: CGSize(width: 40, height: 54)
            case .snowGlobe: CGSize(width: 54, height: 60)
            }
        }

        /// Ha una fiamma o lampadine che si muovono (ferme con Riduci movimento, a batteria e con i giochi in pausa).
        var flickers: Bool { self == .lights || self == .candle || self == .bonfire }
    }

    var id = UUID()
    var kind: Kind
    var screen: String
    var center: CGPoint = .zero
    var scale: CGFloat = 1
    /// Radianti, in senso antiorario.
    var rotation: CGFloat = 0
    /// Le estremità delle luci (per le altre decorazioni non contano).
    var start: CGPoint = .zero
    var end: CGPoint = .zero

    init(kind: Kind, screen: String, center: CGPoint, scale: CGFloat = 1, rotation: CGFloat = 0) {
        self.kind = kind
        self.screen = screen
        self.center = center
        self.scale = scale
        self.rotation = rotation
        let half = kind.size.width / 2
        start = CGPoint(x: center.x - half, y: center.y)
        end = CGPoint(x: center.x + half, y: center.y)
    }

    /// Le luci, dalle due estremità.
    init(kind: Kind, screen: String, start: CGPoint, end: CGPoint) {
        self.init(kind: kind, screen: screen, center: CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2))
        self.start = start
        self.end = end
    }

    // MARK: - Luci

    /// Il filo delle luci, da `start` a `end`: pende in mezzo, di più se è lungo.
    var wire: [CGPoint] {
        let length = hypot(end.x - start.x, end.y - start.y)
        let sag = max(Tuning.lightsMinSag, length * Tuning.lightsSag)
        let count = 24
        return (0...count).map { i in
            let t = CGFloat(i) / CGFloat(count)
            return CGPoint(x: start.x + (end.x - start.x) * t, y: start.y + (end.y - start.y) * t - sag * 4 * t * (1 - t))
        }
    }

    /// Quale estremità delle luci è sotto il punto (0 = `start`, 1 = `end`), o nil.
    func end(near point: CGPoint) -> Int? {
        let distances = [start, end].map { hypot($0.x - point.x, $0.y - point.y) }
        guard let nearest = distances.indices.min(by: { distances[$0] < distances[$1] }),
              distances[nearest] <= Tuning.lightsGrab else { return nil }
        return nearest
    }

    mutating func moveEnd(_ index: Int, to point: CGPoint) {
        if index == 0 { start = point } else { end = point }
        center = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
    }

    // MARK: - Spostare, ingrandire, girare

    /// Dove si disegna, in coordinate dello schermo: le luci con le lampadine, le altre girate e ingrandite.
    var frame: CGRect {
        if kind == .lights {
            let xs = wire.map(\.x), ys = wire.map(\.y)
            let margin = Tuning.bulbRadius * 2 * scale
            return CGRect(x: (xs.min() ?? 0) - margin, y: (ys.min() ?? 0) - margin,
                          width: (xs.max() ?? 0) - (xs.min() ?? 0) + margin * 2,
                          height: (ys.max() ?? 0) - (ys.min() ?? 0) + margin * 2)
        }
        let w = kind.size.width * scale, h = kind.size.height * scale
        let c = abs(cos(rotation)), s = abs(sin(rotation))
        let size = CGSize(width: w * c + h * s, height: w * s + h * c)
        return CGRect(x: center.x - size.width / 2, y: center.y - size.height / 2, width: size.width, height: size.height)
    }

    mutating func move(by delta: CGVector) {
        center.x += delta.dx
        center.y += delta.dy
        start.x += delta.dx
        start.y += delta.dy
        end.x += delta.dx
        end.y += delta.dy
    }

    mutating func resize(by factor: CGFloat) {
        scale = min(max(scale * factor, Tuning.deskScale.lowerBound), Tuning.deskScale.upperBound)
    }

    mutating func turn(by radians: CGFloat) {
        rotation = (rotation + radians).truncatingRemainder(dividingBy: 2 * .pi)
    }

    // MARK: - Schermi

    /// La stessa decorazione su `screen`, spostata quanto basta per stare dentro uno schermo grande `size`
    /// (uno schermo più piccolo, o il principale quando il suo non c'è più).
    func placed(on screen: String, size: CGSize) -> DeskItem {
        var item = self
        item.screen = screen
        let f = item.frame
        func shift(_ low: CGFloat, _ high: CGFloat, _ limit: CGFloat) -> CGFloat {
            low < 0 || high - low > limit ? -low : high > limit ? limit - high : 0
        }
        item.move(by: CGVector(dx: shift(f.minX, f.maxX, size.width), dy: shift(f.minY, f.maxY, size.height)))
        return item
    }

    /// `items` con `item` in più; oltre `Tuning.maxDeskItems` sul suo schermo sparisce la più vecchia di quello schermo.
    static func adding(_ item: DeskItem, to items: [DeskItem]) -> [DeskItem] {
        var items = items + [item]
        while items.filter({ $0.screen == item.screen }).count > Tuning.maxDeskItems,
              let oldest = items.firstIndex(where: { $0.screen == item.screen }) {
            items.remove(at: oldest)
        }
        return items
    }
}
