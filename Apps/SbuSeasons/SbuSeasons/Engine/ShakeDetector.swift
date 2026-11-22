import CoreGraphics
import Foundation

/// Riconosce uno scuotimento: il punto cambia verso più volte, in fretta, con un tragitto abbastanza lungo.
/// Si guarda in orizzontale e in verticale, ognuno per conto suo.
nonisolated struct ShakeDetector {
    /// Quanti cambi di verso servono, entro quanti secondi, e quanto deve essere lungo ogni tratto.
    var reversals: Int
    var window: TimeInterval
    var minTravel: CGFloat

    // Init scritto a mano: con le proprietà `private` qui sotto, lo Swift di Xcode 26 rende privato
    // quello automatico e da un altro file resta solo `init()` (SBU-206).
    init(reversals: Int = 4, window: TimeInterval = 1, minTravel: CGFloat = 40) {
        self.reversals = reversals
        self.window = window
        self.minTravel = minTravel
    }

    private var axes = [Axis(), Axis()]
    private var times: [TimeInterval] = []
    /// Dopo una scossa si aspetta `window` secondi: chi continua a scuotere fa una scossa sola.
    private var quietUntil: TimeInterval = -.infinity

    // Esplicito: con le proprietà private, lo Swift della CI rende privato l'init membro a membro (SBU-160).
    init(reversals: Int = 4, window: TimeInterval = 1, minTravel: CGFloat = 40) {
        self.reversals = reversals
        self.window = window
        self.minTravel = minTravel
    }

    /// Un punto nuovo. true = scosso (poi si ricomincia a contare).
    mutating func add(_ point: CGPoint, at time: TimeInterval) -> Bool {
        let reversedX = axes[0].reverses(at: point.x, minTravel: minTravel)
        let reversedY = axes[1].reverses(at: point.y, minTravel: minTravel)
        // Durante la pausa dopo una scossa i cambi di verso non contano: se no, a pausa finita,
        // quelli dello stesso gesto farebbero una seconda scossa a cursore fermo.
        guard time >= quietUntil else { return false }
        if reversedX { times.append(time) }
        if reversedY { times.append(time) }
        times.removeAll { time - $0 > window }
        guard times.count >= reversals else { return false }
        times = []
        quietUntil = time + window
        return true
    }

    /// Un asse: il punto più lontano raggiunto e il verso in cui si va.
    private struct Axis {
        var extreme: CGFloat?
        var direction: CGFloat = 0

        mutating func reverses(at value: CGFloat, minTravel: CGFloat) -> Bool {
            guard let extreme else {
                self.extreme = value
                return false
            }
            let travel = value - extreme
            if direction == 0 || travel * direction > 0 {
                // Stesso verso (o il primo): l'estremo va avanti. Il primo verso conta solo oltre `minTravel`.
                if direction != 0 || abs(travel) >= minTravel {
                    direction = travel > 0 ? 1 : -1
                    self.extreme = value
                }
                return false
            }
            guard abs(travel) >= minTravel else { return false }
            direction = -direction
            self.extreme = value
            return true
        }
    }
}
