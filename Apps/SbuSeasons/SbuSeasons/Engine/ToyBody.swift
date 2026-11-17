import CoreGraphics
import Foundation

/// Il corpo di un oggetto con cui giocare: dove sono i suoi piedi (centro in basso), come si muove,
/// su che cosa poggia. Solo fisica, niente disegno: si prova senza SpriteKit.
nonisolated struct ToyBody: Equatable {
    var position: CGPoint
    var velocity: CGVector = .zero
    /// In mano al cursore: non cade e non si muove da solo.
    private(set) var isHeld = false
    /// Fermo in piedi su un bordo.
    private(set) var isResting = false

    init(position: CGPoint) {
        self.position = position
    }

    mutating func hold(at point: CGPoint) {
        isHeld = true
        isResting = false
        velocity = .zero
        position = point
    }

    /// Lasciato andare: parte con la velocità del lancio (zero = cade dritto).
    mutating func release(velocity: CGVector) {
        isHeld = false
        let speed = hypot(velocity.dx, velocity.dy)
        let scale = speed > Tuning.toyMaxThrow ? Tuning.toyMaxThrow / speed : 1
        self.velocity = CGVector(dx: velocity.dx * scale, dy: velocity.dy * scale)
    }

    /// Un passo. `ledges`: dove si può posare; `width`: la larghezza dello schermo, da cui non esce;
    /// `bounce`: quanta velocità resta dopo un urto (0 = si ferma subito).
    mutating func step(dt: CGFloat, ledges: [Ledge], width: CGFloat, bounce: CGFloat) {
        guard !isHeld else { return }
        let previous = position
        isResting = velocity.dy <= 0 && ledges.contains { abs($0.y - position.y) < 0.5 && $0.span.contains(position.x) }
        if isResting {
            // In piedi: scivola un po' e si ferma. Se esce dal bordo, al passo dopo cade.
            velocity = CGVector(dx: velocity.dx * CGFloat(exp(-Double(Tuning.toyFriction * dt))), dy: 0)
            position.x += velocity.dx * dt
        } else {
            velocity.dy -= Tuning.toyGravity * dt
            position.x += velocity.dx * dt
            position.y += velocity.dy * dt
        }
        if position.x < 0 || position.x > width {
            position.x = min(max(position.x, 0), width)
            velocity.dx = -velocity.dx * bounce
        }
        // Ha attraversato un bordo scendendo: si posa sul più alto.
        guard velocity.dy < 0,
              let top = ledges.filter({ $0.span.contains(position.x) && previous.y >= $0.y && position.y <= $0.y })
                  .map(\.y).max()
        else { return }
        position.y = top
        let up = -velocity.dy * bounce
        velocity.dy = up > Tuning.toyMinBounce ? up : 0
        isResting = velocity.dy == 0
    }
}
