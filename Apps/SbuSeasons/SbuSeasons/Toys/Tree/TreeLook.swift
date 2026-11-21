import CoreGraphics

/// Com'è fatto un albero: quanto è cresciuto, le decorazioni appese e quale si appende col prossimo clic.
/// Solo dati: si prova senza SpriteKit e si salva com'è (`KeptToys`). Le coordinate sono quelle dell'albero
/// a grandezza 1, dai piedi: crescendo, le decorazioni crescono con lui.
nonisolated struct TreeLook: Codable, Equatable, Sendable {
    var growth: CGFloat = 1
    var decorations: [Decoration] = []
    var hanging = DecorationKind.bauble

    /// Dove comincia e finisce la chioma (pt dai piedi) e quanto è larga in basso, per lato.
    static let foliage: ClosedRange<CGFloat> = 10...76
    static let halfWidth: CGFloat = 30
    /// La punta, dove va la stella.
    static let tip = CGPoint(x: 0, y: 77)
    /// Quanti colori hanno le palline (`ChristmasTree.colors`).
    static let colorCount = 5

    /// Il punto è sui rami? La chioma è un triangolo: largo in basso, a punta in alto.
    static func isOnBranch(_ point: CGPoint) -> Bool {
        guard foliage.contains(point.y) else { return false }
        let reach = halfWidth * (1 - (point.y - foliage.lowerBound) / (foliage.upperBound - foliage.lowerBound))
        return abs(point.x) <= reach
    }

    /// Un clic sui rami: appende `hanging` lì (la stella in cima, al posto di quella che c'era). false = niente.
    @discardableResult
    mutating func hang(at point: CGPoint) -> Bool {
        guard Self.isOnBranch(point) else { return false }
        if hanging.isTopper {
            decorations.removeAll { $0.kind.isTopper }
            decorations.append(Decoration(kind: hanging, position: Self.tip))
            return true
        }
        guard decorations.count < Tuning.maxDecorations else { return false }
        let baubles = decorations.filter { $0.kind == .bauble }.count
        decorations.append(Decoration(kind: hanging, position: point, color: baubles % Self.colorCount))
        return true
    }

    /// La decorazione sotto il punto, quella davanti (l'ultima appesa).
    func decoration(at point: CGPoint) -> Int? {
        decorations.indices.last { decorations[$0].contains(point) }
    }

    mutating func move(_ index: Int, to point: CGPoint) {
        guard decorations.indices.contains(index) else { return }
        decorations[index].position = point
    }

    /// Lasciata dopo il trascinamento: sui rami resta lì, fuori dall'albero si toglie.
    mutating func drop(_ index: Int, at point: CGPoint) {
        guard decorations.indices.contains(index) else { return }
        if Self.isOnBranch(point) || decorations[index].kind.isTopper && hypot(point.x - Self.tip.x, point.y - Self.tip.y) < 10 {
            decorations[index].position = point
        } else {
            decorations.remove(at: index)
        }
    }

    mutating func resize(_ index: Int, by factor: CGFloat) {
        guard decorations.indices.contains(index) else { return }
        let range = Tuning.decorationScale
        decorations[index].scale = min(max(decorations[index].scale * factor, range.lowerBound), range.upperBound)
    }

    mutating func turn(_ index: Int, by radians: CGFloat) {
        guard decorations.indices.contains(index) else { return }
        decorations[index].rotation = (decorations[index].rotation + radians).truncatingRemainder(dividingBy: 2 * .pi)
    }

    mutating func remove(_ index: Int) {
        guard decorations.indices.contains(index) else { return }
        decorations.remove(at: index)
    }

    /// Più alto (factor > 1) o più basso, entro `Tuning.treeGrowth`.
    mutating func grow(by factor: CGFloat) {
        let range = Tuning.treeGrowth
        growth = min(max(growth * factor, range.lowerBound), range.upperBound)
    }
}
