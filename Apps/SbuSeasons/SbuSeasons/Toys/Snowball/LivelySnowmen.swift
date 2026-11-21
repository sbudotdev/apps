import CoreGraphics

/// Pupazzi vivi (SBU-187): due pupazzi vicini ogni tanto si tirano una palla, e una palla in volo abbatte lo Yeti.
/// Il resto (viaggiano con la finestra, saltano se la scuoti, si rompono lanciati forte) è in `SeasonScene`.
extension SeasonScene {
    /// A ogni passo dei giochi.
    func stepLivelySnowmen() {
        knockDownTheYeti()
        guard Settings.shared.values.snowballFights, !reduceMotion else { return }
        guard let due = nextFight else {
            nextFight = elapsed + .random(in: Tuning.fightInterval)
            return
        }
        guard elapsed >= due else { return }
        nextFight = elapsed + .random(in: Tuning.fightInterval)
        snowballFight()
    }

    /// Una palla in volo che tocca lo Yeti lo fa cadere, e si rompe.
    private func knockDownTheYeti() {
        guard let yeti, !yeti.knockedDown else { return }
        let hit = toys.first { toy in
            guard toy is Snowball, !toy.body.isResting, !toy.body.isHeld else { return false }
            return hypot(toy.body.velocity.dx, toy.body.velocity.dy) > Tuning.toyMinBounce && toy.frame.intersects(yeti.frame)
        }
        guard let hit else { return }
        yeti.knockDown()
        shatter(hit)
    }

    /// Due pupazzi fermi sullo stesso bordo, a distanza giusta: uno tira una palla all'altro, che si rompe all'arrivo.
    /// false = non c'è nessuna coppia (o Riduci movimento).
    @discardableResult
    func snowballFight() -> Bool {
        guard !reduceMotion, !toysPaused else { return false }
        let snowmen = toys.compactMap { $0 as? Snowman }.filter { $0.body.isResting && !$0.body.isHeld }
        var pairs: [(Snowman, Snowman)] = []
        for a in snowmen {
            for b in snowmen where a !== b && abs(a.body.position.y - b.body.position.y) < 0.5
                && Tuning.fightReach.contains(abs(a.body.position.x - b.body.position.x)) {
                pairs.append((a, b))
            }
        }
        guard let (thrower, target) = pairs.randomElement() else { return false }
        let start = CGPoint(x: thrower.body.position.x, y: thrower.body.position.y + thrower.node.size.height * 0.6)
        let ball = makeSnowball(at: start)
        ball.body.release(velocity: lob(from: start, to: target.body.position, time: Tuning.fightFlight))
        ball.thrownHard = true
        SoundBoard.shared.play("palla-di-neve-lancio")
        return true
    }
}

/// La velocità con cui lanciare da `start` per arrivare a `target` in `time` secondi, con la gravità degli oggetti.
nonisolated func lob(from start: CGPoint, to target: CGPoint, time: CGFloat) -> CGVector {
    CGVector(dx: (target.x - start.x) / time,
             dy: (target.y - start.y) / time + Tuning.toyGravity * time / 2)
}
