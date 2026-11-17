import CoreGraphics

/// I personaggi sulla scena: uno per tipo, si mettono e si tolgono dal menu. Solo d'inverno: cambiando stagione spariscono.
extension SeasonScene {

    func hasFigure(_ kind: FigureKind) -> Bool {
        toys.contains { ($0 as? Figure)?.kind == kind }
    }

    /// La voce del menu: lo mette se non c'è, se no lo toglie. true = adesso c'è.
    @discardableResult
    func toggleFigure(_ kind: FigureKind) -> Bool {
        if hasFigure(kind) {
            toys.filter { ($0 as? Figure)?.kind == kind }.forEach(remove)
            return false
        }
        guard season is Snow else { return false }
        add(makeFigure(kind))
        return true
    }

    /// La renna sopra la finestra più in alto (senza finestre, sul Dock o sul fondo); gli altri sul fondo, in un punto a caso.
    private func makeFigure(_ kind: FigureKind) -> Figure {
        let ground = CGPoint(x: .random(in: size.width * 0.15...size.width * 0.85), y: 0)
        switch kind {
        case .fox: return Fox(at: ground)
        case .tit: return Feeder(at: ground)
        case .cabin: return Cabin(at: ground)
        case .lantern: return Lantern(at: ground)
        case .reindeer:
            let room = (ceiling ?? size.height) - 34
            let ledge = ledges.filter { $0 != dockLedge && $0.y <= room }.max { $0.y < $1.y } ?? dockLedge
            return Reindeer(at: ledge.map { CGPoint(x: ($0.span.lowerBound + $0.span.upperBound) / 2, y: $0.y) } ?? ground)
        }
    }

    /// A ogni passo (se i giochi non sono in pausa): volpe e renna camminano sul loro bordo, il naso della renna
    /// segue il cursore (`mouse`, coordinate della scena).
    func stepFigures(mouse: CGPoint) {
        let floor = Ledge(y: 0, span: 0...size.width)
        for figure in toys.compactMap({ $0 as? Figure }) {
            (figure as? Reindeer)?.light(mouse: mouse)
            // Ferma (o la volpe che ha finito di camminare: l'attrito la ferma), in aria o in mano: niente passi.
            guard let speed = figure.walkSpeed, figure.body.isResting else { continue }
            let feet = figure.body.position
            let span = (ledges.first { abs($0.y - feet.y) < 0.5 && $0.span.contains(feet.x) } ?? floor).span
            figure.heading = Pacing.heading(x: feet.x, span: span, heading: figure.heading, margin: figure.node.size.width / 2)
            figure.body.velocity.dx = figure.heading * speed * (reduceMotion ? 0.5 : 1)
        }
    }

    /// Cambiando stagione.
    func removeFigures() {
        toys.filter { $0 is Figure }.forEach(remove)
    }
}
