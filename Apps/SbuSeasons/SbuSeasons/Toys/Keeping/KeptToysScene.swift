import CoreGraphics

/// Alberi e pupazzi della scena da salvare, e di ritorno al riavvio (`KeptToys`). Solo d'inverno, come i giochi.
extension SeasonScene {
    func keptToys(screen: String) -> KeptToys {
        KeptToys(
            trees: toys.compactMap { $0 as? ChristmasTree }.map { .init(screen: screen, position: $0.body.position, look: $0.look) },
            snowmen: toys.compactMap { $0 as? Snowman }.map { .init(screen: screen, position: $0.body.position, look: $0.look) }
        )
    }

    /// Rimette gli oggetti salvati, dentro lo schermo (uno più piccolo di prima li stringe). Fuori dall'inverno niente:
    /// cambiando stagione si sciolgono, come prima.
    func restore(_ kept: KeptToys) {
        guard season is Snow else { return }
        func inside(_ p: CGPoint) -> CGPoint {
            CGPoint(x: min(max(p.x, 0), size.width), y: min(max(p.y, 0), (ceiling ?? size.height) - 1))
        }
        for tree in kept.trees.suffix(Tuning.maxTrees) { add(ChristmasTree(at: inside(tree.position), look: tree.look)) }
        for snowman in kept.snowmen { add(Snowman(at: inside(snowman.position), look: snowman.look)) }
    }
}
