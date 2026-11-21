import CoreGraphics

/// Yeti e trenino sulla scena (SBU-178): entrano da un lato, fanno la loro cosa, escono dall'altro; `Visitors` li
/// fa passare di schermo in schermo. Solo d'inverno; "Metti in pausa i giochi" e il cambio di stagione li tolgono.
extension SeasonScene {
    var yeti: Yeti? { toys.lazy.compactMap { $0 as? Yeti }.first }

    func isVisiting(_ kind: VisitorKind) -> Bool {
        switch kind {
        case .yeti: yeti != nil
        case .train: train != nil
        }
    }

    // MARK: - Yeti

    /// Lo Yeti entra dal lato da cui arriva (`heading` 1 = da sinistra), sul fondo. `carrying`: il pupazzo che
    /// si è già preso su uno schermo prima. nil = non è inverno, i giochi sono in pausa o c'è già.
    @discardableResult
    func sendYeti(heading: CGFloat, carrying: SnowmanLook? = nil) -> Yeti? {
        guard season is Snow, !toysPaused, yeti == nil else { return nil }
        let yeti = Yeti(at: CGPoint(x: entryX(heading: heading, width: 36), y: 0), heading: heading)
        add(yeti)
        if let carrying {
            let snowman = Snowman(at: yeti.shoulders, look: carrying)
            snowman.body.hold(at: yeti.shoulders)
            add(snowman)
            yeti.carried = snowman
        }
        return yeti
    }

    /// Fuori dallo schermo, dal lato da cui entra chi va verso `heading`.
    private func entryX(heading: CGFloat, width: CGFloat) -> CGFloat {
        heading > 0 ? -width / 2 : size.width + width / 2
    }

    /// Un passo dello Yeti: va dal pupazzo più vicino, lo prende, se ne va; esce di lato.
    private func stepYeti() {
        guard let yeti else { return }
        if yeti.knockedDown {
            yeti.body.velocity.dx = 0
            guard yeti.isGone else { return }
            remove(yeti)
            onVisitorLeft?(.yeti, VisitorExit(heading: yeti.heading, fled: true))
            return
        }
        if let carried = yeti.carried {
            if heldToy === carried || !toys.contains(where: { $0 === carried }) {
                // Glielo hai tolto di mano: se ne va a mani vuote.
                yeti.carried = nil
                yeti.gaveUp = true
            } else {
                carried.body.hold(at: yeti.shoulders)
                carried.node.position = yeti.shoulders
            }
        }
        let feet = yeti.body.position
        let half = yeti.node.size.width
        if feet.x < -half || feet.x > size.width + half {
            let exit = VisitorExit(heading: feet.x < 0 ? -1 : 1, carrying: yeti.carried?.look, fled: yeti.fleeing)
            if let carried = yeti.carried { remove(carried) }
            remove(yeti)
            onVisitorLeft?(.yeti, exit)
            return
        }
        guard yeti.body.isResting else { return }
        let calm: CGFloat = reduceMotion ? 0.5 : 1
        if yeti.fleeing {
            yeti.body.velocity.dx = yeti.heading * Tuning.yetiDash * calm
            return
        }
        if yeti.carried != nil || yeti.gaveUp {
            yeti.body.velocity.dx = yeti.heading * Tuning.yetiCarry * calm
            return
        }
        let snowmen = toys.compactMap { $0 as? Snowman }.filter { $0 !== heldToy }
        guard let target = snowmen.min(by: { abs($0.body.position.x - feet.x) < abs($1.body.position.x - feet.x) }) else {
            yeti.body.velocity.dx = yeti.heading * Tuning.yetiWalk * calm
            return
        }
        let gap = target.body.position.x - feet.x
        let rise = target.body.position.y - feet.y
        if abs(gap) < Tuning.yetiReach, rise <= 1 {
            // Lo prende (anche un po' più in basso: si china) e prosegue per la sua strada.
            yeti.carried = target
            target.body.hold(at: yeti.shoulders)
            SoundBoard.shared.play("yeti")
            return
        }
        if rise > 1, abs(gap) < Tuning.yetiJumpReach {
            // Più in alto: ci salta sopra (con Riduci movimento ci si trova e basta).
            if reduceMotion {
                yeti.body.position = target.body.position
                yeti.node.position = yeti.body.position
            } else {
                let up = (2 * Tuning.toyGravity * (rise + Tuning.yetiJumpClearance)).squareRoot()
                let down = (2 * Tuning.toyGravity * Tuning.yetiJumpClearance).squareRoot()
                yeti.body.velocity = CGVector(dx: gap / ((up + down) / Tuning.toyGravity), dy: up)
            }
            return
        }
        yeti.heading = gap > 0 ? 1 : -1
        yeti.body.velocity.dx = yeti.heading * Tuning.yetiWalk * calm
    }

    // MARK: - Trenino

    /// Il trenino entra dal lato da cui arriva e corre sul fondo; se `carriesGift`, l'elfo lascia un regalo.
    /// Con Riduci movimento non attraversa lo schermo: il regalo arriva dritto dove sarebbe caduto.
    /// nil = non è inverno, i giochi sono in pausa o c'è già.
    @discardableResult
    func sendTrain(heading: CGFloat, carriesGift: Bool) -> Train? {
        guard season is Snow, !toysPaused, train == nil else { return nil }
        let train = Train(heading: heading)
        train.dropX = carriesGift ? .random(in: size.width * Tuning.elfDropSpan.lowerBound...size.width * Tuning.elfDropSpan.upperBound) : nil
        if reduceMotion {
            if let x = train.dropX { add(Gift(at: CGPoint(x: x, y: 0), fromElf: true)) }
            return train
        }
        train.node.position = CGPoint(x: entryX(heading: heading, width: train.node.size.width), y: 0)
        addChild(train.node)
        self.train = train
        return train
    }

    private func stepTrain(dt: CGFloat) {
        guard let train else { return }
        var p = train.node.position
        p.x += train.heading * Tuning.trainSpeed * dt
        train.node.position = p
        if let x = train.dropX, train.heading > 0 ? p.x >= x : p.x <= x {
            train.dropX = nil
            let gift = Gift(at: CGPoint(x: x, y: Tuning.elfGiftHeight), fromElf: true)
            gift.body.velocity = CGVector(dx: -train.heading * Tuning.elfGiftThrow.dx, dy: Tuning.elfGiftThrow.dy)   // l'elfo lo lancia giù dal vagone
            add(gift)
            SoundBoard.shared.play("regalo")
        }
        let half = train.node.size.width
        if p.x < -half || p.x > size.width + half {
            train.node.removeFromParent()
            self.train = nil
            onVisitorLeft?(.train, VisitorExit(heading: train.heading))
        }
    }

    // MARK: - Regalo dell'elfo

    /// Il regalo del trenino aperto: una decorazione su un albero, un vestito al pupazzo o un albero nuovo.
    func unwrapElfGift(_ gift: Gift) {
        let feet = gift.body.position
        func nearest<T: Toy>(_ type: T.Type) -> T? {
            toys.compactMap { $0 as? T }.min { abs($0.body.position.x - feet.x) < abs($1.body.position.x - feet.x) }
        }
        let tree = nearest(ChristmasTree.self)
        let snowman = nearest(Snowman.self)
        let present = ElfPresent.pick(hasTree: tree != nil, snowman: snowman?.look, roll: .random(in: 0..<1))
        switch present {
        case .decoration(let kind):
            guard let tree else { return }
            var look = tree.look
            let hanging = look.hanging
            look.hanging = kind
            let y = CGFloat.random(in: Tuning.elfDecorationHeight)
            let reach = TreeLook.halfWidth * (1 - (y - TreeLook.foliage.lowerBound) / (TreeLook.foliage.upperBound - TreeLook.foliage.lowerBound))
            look.hang(at: CGPoint(x: .random(in: -reach * 0.7...reach * 0.7), y: y))
            look.hanging = hanging
            tree.look = look
            sparkle(at: CGPoint(x: tree.body.position.x, y: tree.body.position.y + tree.node.size.height / 2))
        case .hat(let hat):
            dress(snowman) { $0.hat = hat }
        case .scarf(let scarf):
            dress(snowman) { $0.scarf = scarf }
        case .buttons:
            dress(snowman) { $0.buttons = true }
        case .tree:
            add(ChristmasTree(at: CGPoint(x: feet.x, y: feet.y)))
            let trees = toys.compactMap { $0 as? ChristmasTree }
            trees.prefix(max(0, trees.count - Tuning.maxTrees)).forEach(remove)
        }
    }

    private func dress(_ snowman: Snowman?, _ change: (inout SnowmanLook) -> Void) {
        guard let snowman else { return }
        change(&snowman.look)
        sparkle(at: CGPoint(x: snowman.body.position.x, y: snowman.body.position.y + snowman.node.size.height))
    }

    // MARK: - Passo

    /// A ogni passo, se i giochi non sono in pausa.
    func stepVisitors(dt: CGFloat) {
        guard season is Snow else { return }
        stepYeti()
        stepTrain(dt: dt)
    }

    /// In pausa e cambiando stagione: via Yeti e trenino. Il pupazzo che lo Yeti aveva in spalla resta e cade.
    func removeVisitors() {
        if let yeti {
            yeti.carried?.body.release(velocity: .zero)
            yeti.carried = nil
            remove(yeti)
        }
        train?.node.removeFromParent()
        train = nil
    }
}
