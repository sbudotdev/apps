import AppKit
import SpriteKit

/// La neve posata su un bordo orizzontale (il lato superiore di una finestra, o il fondo dello schermo).
/// È una "mappa di altezze": una colonna ogni `step` punti, ognuna con la sua altezza di neve.
/// Coordinate: quelle della scena (locali allo schermo).
final class SnowPile {

    static let step = Tuning.pileStep

    // MARK: - Stato

    let minX: CGFloat
    let baseY: CGFloat
    var maxHeight: CGFloat
    private(set) var heights: [CGFloat]
    /// Colonne su cui può cadere neve (non coperte da altre finestre).
    private var open: [Bool]
    /// Angoli stondati: di quanto si abbassa la base di ogni colonna (segue l'arco dell'angolo)…
    private let sag: [CGFloat]
    /// …e quanta parte dell'altezza massima può tenere (verso il bordo la neve scivola via).
    private let capacity: [CGFloat]
    private var dirty = false
    let cornerRadius: CGFloat

    let node = SKShapeNode()

    /// `cornerRadius`: raggio degli angoli superiori della superficie (0 = spigoli vivi).
    init(minX: CGFloat, width: CGFloat, baseY: CGFloat, cornerRadius: CGFloat, maxHeight: CGFloat) {
        self.minX = minX
        self.baseY = baseY
        self.maxHeight = maxHeight
        self.cornerRadius = cornerRadius
        let count = max(1, Int(width / Self.step))
        heights = Array(repeating: 0, count: count)
        open = Array(repeating: true, count: count)

        // Distanza di ogni colonna dal bordo più vicino → posizione sull'arco dell'angolo.
        let r = min(cornerRadius, width / 2)
        let edgeDistance = (0..<count).map { i in
            min(CGFloat(i) + 0.5, CGFloat(count - i) - 0.5) * Self.step
        }
        sag = edgeDistance.map { d in d >= r ? 0 : r - (r * r - (r - d) * (r - d)).squareRoot() }
        capacity = edgeDistance.map { d in r > 0 ? min(1, d / r) : 1 }

        // Bianco appena azzurrato, così si vede anche sulle finestre bianche.
        // Niente contorno: ridisegnarlo a ogni frame costa molta CPU.
        node.fillColor = NSColor(calibratedRed: 0.94, green: 0.97, blue: 1.0, alpha: 1)
        node.strokeColor = .clear
        node.lineWidth = 0
        node.zPosition = 2   // sopra i fiocchi (che hanno zPosition 0…1)
    }

    var isEmpty: Bool { !heights.contains { $0 > 0.05 } }

    private func column(at x: CGFloat) -> Int? {
        let i = Int((x - minX) / Self.step)
        return heights.indices.contains(i) ? i : nil
    }

    private func x(of column: Int) -> CGFloat { minX + (CGFloat(column) + 0.5) * Self.step }
    /// Dove poggia la neve nella colonna `i` (più in basso sugli angoli stondati).
    private func base(_ i: Int) -> CGFloat { baseY - sag[i] }
    private func cap(_ i: Int) -> CGFloat { maxHeight * capacity[i] }

    /// Altezza della superficie della neve in `x`, oppure nil se lì non si può posare niente.
    func surface(at x: CGFloat) -> CGFloat? {
        guard let i = column(at: x), open[i] else { return nil }
        return base(i) + heights[i]
    }

    // MARK: - Modifiche

    /// Un fiocco di raggio `radius` si è posato in `x`.
    /// `growth` = quanta neve aggiunge per colonna toccata.
    func add(atX x: CGFloat, radius: CGFloat, growth: CGFloat) {
        let reach = max(1, Int(radius / Self.step))
        guard let center = column(at: x) else { return }
        for i in max(0, center - reach)...min(heights.count - 1, center + reach) where open[i] {
            heights[i] = min(cap(i), heights[i] + growth)
        }
        dirty = true
    }

    /// Aggiorna quali tratti sono scoperti. Restituisce i punti dove c'era neve che ora
    /// è finita sotto un'altra finestra: la scena la farà cadere come fiocchi.
    func setOpen(_ ranges: [ClosedRange<CGFloat>]) -> [CGPoint] {
        var released: [CGPoint] = []
        for i in heights.indices {
            let x = x(of: i)
            open[i] = ranges.contains { $0.contains(x) }
            if !open[i], heights[i] > 0 {
                released += flakes(column: i, amount: heights[i])
                heights[i] = 0
                dirty = true
            }
        }
        return released
    }

    /// Tutta la neve diventa fiocchi (finestra spostata o chiusa).
    func releaseAll() -> [CGPoint] {
        var released: [CGPoint] = []
        for i in heights.indices where heights[i] > 0 {
            released += flakes(column: i, amount: heights[i])
            heights[i] = 0
        }
        dirty = true
        return released
    }

    func clear() {
        guard !isEmpty else { return }
        heights = heights.map { _ in 0 }
        dirty = true
    }

    /// Il cursore in `point` spazza via la neve entro `radius` (in orizzontale), lasciando una tacca.
    /// Restituisce i punti da cui far partire i granelli di polvere.
    func scoop(at point: CGPoint, radius: CGFloat) -> [CGPoint] {
        guard point.y > baseY - (sag.max() ?? 0) - 4, point.y < baseY + maxHeight + 4,
              let first = column(at: max(minX, point.x - radius)),
              let last = column(at: min(minX + CGFloat(heights.count) * Self.step - 0.01, point.x + radius))
        else { return [] }
        var released: [CGPoint] = []
        for i in first...last where heights[i] > 0 && point.y < base(i) + heights[i] + 3 {
            released += flakes(column: i, amount: heights[i])
            heights[i] = 0
            dirty = true
        }
        return released
    }

    /// Frana: dove la neve è troppo ripida scivola sulle colonne vicine.
    /// Ai bordi di un tratto scoperto la neve in eccesso cade giù (si perde).
    func settle() {
        guard !isEmpty else { return }
        for i in heights.indices where open[i] {
            let left = i > 0 && open[i - 1] ? heights[i - 1] : 0
            let right = i < heights.count - 1 && open[i + 1] ? heights[i + 1] : 0
            for (neighbor, height) in [(i - 1, left), (i + 1, right)] {
                let excess = heights[i] - height - Tuning.pileMaxSlope
                guard excess > 0 else { continue }
                let moved = excess * 0.4
                heights[i] -= moved
                if heights.indices.contains(neighbor), open[neighbor] {
                    heights[neighbor] = min(cap(neighbor), heights[neighbor] + moved)   // oltre il limite cade giù
                }
                if moved > 0.05 { dirty = true }   // le micro-frane non meritano un ridisegno
            }
        }
    }

    /// Ridisegna la forma solo se qualcosa è cambiato dall'ultima volta.
    /// Ogni tratto continuo di neve è un poligono: profilo superiore da sinistra a destra,
    /// poi la base (che segue gli angoli stondati) da destra a sinistra.
    func redrawIfNeeded() {
        guard dirty else { return }
        dirty = false
        let path = CGMutablePath()
        var run: [Int] = []
        func closeRun() {
            guard let first = run.first, let last = run.last else { return }
            path.move(to: CGPoint(x: minX + CGFloat(first) * Self.step, y: base(first)))
            for i in run { path.addLine(to: CGPoint(x: x(of: i), y: base(i) + heights[i])) }
            path.addLine(to: CGPoint(x: minX + CGFloat(last + 1) * Self.step, y: base(last)))
            for i in run.reversed() { path.addLine(to: CGPoint(x: x(of: i), y: base(i))) }
            path.closeSubpath()
            run = []
        }
        for i in heights.indices {
            if open[i] && heights[i] > 0.05 { run.append(i) } else { closeRun() }
        }
        closeRun()
        node.path = path
    }

    /// I granelli in cui si sbriciolano `amount` punti di neve tolti dalla colonna `i`.
    private func flakes(column i: Int, amount: CGFloat) -> [CGPoint] {
        // ponytail: 1 granello ogni 3 punti di neve, max 3 per colonna; se serve più "polvere", abbassa il divisore.
        let count = min(3, Int((amount / 3).rounded(.up)))
        return (0..<count).map { _ in CGPoint(x: x(of: i), y: base(i) + .random(in: 0...max(1, heights[i]))) }
    }
}
