import CoreGraphics
import Foundation

/// «Meteo a caso» (SBU-177): quale effetto viene dopo. La regola segue la stagione dell'anno (emisfero nord):
/// ogni stagione ha la sua (neve, primavera, estate, autunno) più il meteo di quei mesi. Il sereno no: non cade niente.
enum WeatherShuffle {
    static func pool(month: Int) -> [String] {
        switch month {
        case 3...5: [Spring.id, Rain.id, Storm.id, Clouds.id, Mist.id]
        case 6...8: [Summer.id, Fireflies.id, Meteors.id, Storm.id, Clouds.id]
        case 9...11: [Autumn.id, Rain.id, Mist.id, Clouds.id, Storm.id]
        default: [Snow.id, Mist.id, Clouds.id, Meteors.id]
        }
    }

    /// Un effetto a caso dei mesi di `month`, mai quello che c'è già.
    static func next(after current: String, month: Int) -> String {
        pool(month: month).filter { $0 != current }.randomElement() ?? current
    }
}

/// Quando cambia il meteo: la prima volta dopo un intervallo a caso (`Tuning.weatherShuffle`), poi a ogni cambio
/// un intervallo nuovo. Spento, dimentica l'attesa: riacceso, riparte da capo.
nonisolated struct WeatherClock {
    private var due: TimeInterval?

    /// true = è ora di cambiare.
    mutating func tick(now: TimeInterval, enabled: Bool) -> Bool {
        guard enabled else { due = nil; return false }
        guard let due else {
            self.due = now + .random(in: Tuning.weatherShuffle)
            return false
        }
        guard now >= due else { return false }
        self.due = now + .random(in: Tuning.weatherShuffle)
        return true
    }
}

/// Da quanto il cursore sta fermo (per le lucciole). Fermo vuol dire entro `Tuning.stillSlop` pt dal punto
/// in cui si è fermato: i tremolii della mano non contano.
nonisolated struct Stillness {
    private var anchor: CGPoint?
    private(set) var seconds: CGFloat = 0

    mutating func update(_ point: CGPoint, dt: CGFloat) {
        if let anchor, hypot(point.x - anchor.x, point.y - anchor.y) > Tuning.stillSlop {
            self.anchor = point   // si è mosso: si ricomincia a contare da qui
            seconds = 0
        } else {
            if anchor == nil { anchor = point }
            seconds += dt
        }
    }
}

/// Il bordo che una particella ha attraversato scendendo da `from` a `to`, dentro il suo tratto scoperto. nil = nessuno.
nonisolated func ledgeHit(from: CGPoint, to: CGPoint, ledges: [Ledge]) -> Ledge? {
    ledges.first { from.y >= $0.y && to.y < $0.y && $0.span.contains(to.x) }
}

/// Una finestra copre tutto lo schermo (un'app a schermo intero, non solo ingrandita: quella lascia la barra dei menu).
nonisolated func coversScreen(_ windows: [CGRect], screen: CGRect) -> Bool {
    windows.contains { $0.insetBy(dx: -1, dy: -1).contains(screen) }
}
