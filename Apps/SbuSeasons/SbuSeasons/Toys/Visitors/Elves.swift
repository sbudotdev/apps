import CoreGraphics

/// Gli elfi sulla scena (SBU-187): uno esce dalla neve su un solo schermo, rotola tre palle (fanno un pupazzo da sole,
/// come quelle che rotoli tu) e se ne va. Solo d'inverno; la pausa dei giochi e il cambio di stagione lo tolgono.
extension SeasonScene {
    var elf: Elf? { toys.lazy.compactMap { $0 as? Elf }.first }

    /// L'elfo esce dalla neve sul fondo, nel punto `x` (nil = a caso, lontano dai bordi), con le palle verso `heading`.
    /// nil = non è inverno, i giochi sono in pausa o c'è già.
    @discardableResult
    func sendElf(heading: CGFloat, at x: CGFloat? = nil) -> Elf? {
        guard season is Snow, !toysPaused, elf == nil else { return nil }
        let x = x ?? .random(in: size.width * Tuning.elfDropSpan.lowerBound...size.width * Tuning.elfDropSpan.upperBound)
        let elf = Elf(at: CGPoint(x: x, y: 0), heading: heading)
        add(elf)
        return elf
    }

    /// Un passo dell'elfo: ogni `Tuning.elfRollInterval` una palla accanto all'altra, poi via di lato.
    func stepElf(dt: CGFloat) {
        guard let elf else { return }
        elf.clock += dt
        let feet = elf.body.position
        if elf.balls < 3, elf.clock >= Tuning.elfRise + Tuning.elfRollInterval * CGFloat(elf.balls + 1) {
            let x = feet.x + elf.heading * (Tuning.elfBallGap * CGFloat(elf.balls + 1))
            makeSnowball(at: CGPoint(x: min(max(x, Snowball.radius), size.width - Snowball.radius), y: feet.y))
            elf.balls += 1
            SoundBoard.shared.play("passo-neve")
        }
        guard elf.isLeaving else { return }
        if feet.x < -elf.node.size.width || feet.x > size.width + elf.node.size.width {
            remove(elf)
            onVisitorLeft?(.elves, VisitorExit(heading: elf.heading))
            return
        }
        if elf.body.isResting { elf.body.velocity.dx = elf.heading * Tuning.elfWalk * (reduceMotion ? 0.5 : 1) }
    }
}
