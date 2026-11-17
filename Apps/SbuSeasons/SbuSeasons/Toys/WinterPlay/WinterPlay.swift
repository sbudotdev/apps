import CoreGraphics

/// I giochi d'inverno dal menu: spazzaneve, slittino, funivia, albero di Natale. Solo d'inverno: cambiando stagione spariscono.
extension SeasonScene {

    // MARK: - Spazzaneve

    /// "Manda lo spazzaneve". `dockFirst` ("Prima il Dock"): parte dal Dock; se no dal bordo di finestra più in alto,
    /// e scende di bordo in bordo. nil = non è inverno, o ce n'è già uno in giro.
    @discardableResult
    func sendPlough(dockFirst: Bool) -> Snowplough? {
        guard season is Snow, !toys.contains(where: { $0 is Snowplough }) else { return nil }
        let half = Snowplough.size.width / 2
        // Senza Dock (o senza finestre) parte dal fondo, a sinistra.
        let start = dockFirst ? dockLedge : highestWindowLedge(fitting: Snowplough.size.height)
        let plough = Snowplough(at: start.map { CGPoint(x: $0.span.lowerBound + half, y: $0.y) } ?? CGPoint(x: half, y: 0))
        add(plough)
        SoundBoard.shared.play("spazzaneve")
        return plough
    }

    /// A ogni passo (se i giochi non sono in pausa): la lama raccoglie la neve; al bordo destro dello schermo
    /// lo spazzaneve esce e la neve raccolta resta lì, una montagnetta.
    func stepWinterPlay() {
        for plough in toys.compactMap({ $0 as? Snowplough }) {
            if plough.body.isResting {
                plough.load += everyPile.reduce(0) { $0 + $1.scoop(at: plough.blade, radius: Tuning.ploughBlade).count }
            }
            guard plough.body.position.x >= size.width else { continue }
            remove(plough)
            guard plough.load >= Tuning.moundMinSnow else { continue }
            let mound = Mound(at: CGPoint(x: size.width, y: plough.body.position.y), snow: plough.load)
            mound.body.position.x -= mound.node.size.width / 2
            add(mound)
            let mounds = toys.compactMap { $0 as? Mound }
            mounds.prefix(max(0, mounds.count - Tuning.maxMounds)).forEach(remove)
        }
    }

    // MARK: - Slittino

    /// "Prepara la pista da slittino": uno slittino in cima al bordo di finestra più in alto (senza finestre, sul fondo).
    @discardableResult
    func setUpSledRun() -> Sled? {
        guard season is Snow else { return nil }
        let start = highestWindowLedge(fitting: 14)
        let sled = Sled(at: start.map { CGPoint(x: $0.span.lowerBound + 20, y: $0.y) } ?? CGPoint(x: 40, y: 0))
        add(sled)
        let sleds = toys.compactMap { $0 as? Sled }
        sleds.prefix(max(0, sleds.count - Tuning.maxSleds)).forEach(remove)
        return sled
    }

    // MARK: - Funivia

    var hasCableCar: Bool { toys.contains { $0 is CableCar } }

    /// "Monta la funivia": il palo sul fondo a sinistra e il gancio poco più in là, da trascinare su una finestra.
    @discardableResult
    func setUpCableCar() -> CableCar? {
        guard season is Snow, !hasCableCar else { return nil }
        let car = CableCar(station: CGPoint(x: Tuning.cableStationX, y: 0), hook: CGPoint(x: Tuning.cableStationX + 110, y: 0))
        add(car)
        SoundBoard.shared.play("funivia")
        return car
    }

    /// "Togli la funivia".
    func removeCableCar() {
        toys.filter { $0 is CableCar }.forEach(remove)
    }

    // MARK: - Albero di Natale

    /// "Pianta un albero di Natale": sul fondo, in un punto a caso.
    @discardableResult
    func plantTree() -> ChristmasTree? {
        guard season is Snow else { return nil }
        let tree = ChristmasTree(at: CGPoint(x: .random(in: size.width * 0.15...size.width * 0.85), y: 0))
        add(tree)
        let trees = toys.compactMap { $0 as? ChristmasTree }
        trees.prefix(max(0, trees.count - Tuning.maxTrees)).forEach(remove)
        return tree
    }

    // MARK: - Menu

    /// "Togli alberi, neve e slitte": alberi, montagnette, slittini e spazzaneve. Palle e funivia hanno il loro comando.
    func clearWinterPlay() {
        removeWinterPlay(includingCableCar: false)
    }

    func removeWinterPlay(includingCableCar: Bool) {
        toys.filter { $0 is ChristmasTree || $0 is Mound || $0 is Sled || $0 is Snowplough || (includingCableCar && $0 is CableCar) }
            .forEach(remove)
    }

    /// Il bordo di finestra più in alto dove un oggetto alto `height` non copre la barra dei menu (il Dock no).
    private func highestWindowLedge(fitting height: CGFloat) -> Ledge? {
        let room = (ceiling ?? size.height) - height
        return ledges.filter { $0 != dockLedge && $0.y <= room }.max { $0.y < $1.y }
    }
}
