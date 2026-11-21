import AppKit
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

// MARK: - Secondo giro (SBU-185)

/// Il vento orizzontale in pt/s (più = verso destra). Fisso: soffia sempre dalla stessa parte, con raffiche che
/// scendono al massimo a `Tuning.windGustDip` della forza scelta. Variabile: si alza, si calma e gira ogni
/// mezzo `Tuning.variableWindPeriod`, con la forza scelta (almeno `Tuning.variableWindFloor`).
nonisolated enum Wind {
    static func speed(at t: CGFloat, base: CGFloat, variable: Bool) -> CGFloat {
        if variable {
            let strength = max(abs(base), Tuning.variableWindFloor)
            let turn = sin(t * 2 * .pi / Tuning.variableWindPeriod)
            let gust = 0.75 + 0.25 * sin(t * 0.9)
            return strength * turn * gust
        }
        return base * (Tuning.windGustDip + (1 - Tuning.windGustDip) * (0.5 + 0.5 * sin(t * 0.37)))
    }
}

/// «Pausa quando giochi a un videogioco»: un'app è un gioco se la sua categoria è un tipo di gioco
/// (`public.app-category.games`, `…action-games`…) o se sta tra i giochi di Steam. Tutto in locale.
nonisolated enum VideoGame {
    static func isGame(category: String?, path: String) -> Bool {
        if let category, category.hasPrefix("public.app-category."), category.hasSuffix("games") { return true }
        return path.contains("/steamapps/")
    }

    static func isGame(_ app: NSRunningApplication?) -> Bool {
        guard let url = app?.bundleURL else { return false }
        let category = Bundle(url: url)?.object(forInfoDictionaryKey: "LSApplicationCategoryType") as? String
        return isGame(category: category, path: url.path)
    }
}

/// Se l'effetto gira su uno schermo: tutto quello che lo può fermare, in un posto solo.
nonisolated struct EffectGate {
    var snowing: Bool
    var displaysAsleep: Bool
    var screenCovered: Bool
    var gameInFront: Bool
    var screenOff: Bool
    var stopOnBattery: Bool
    var onBattery: Bool

    var runs: Bool {
        snowing && !displaysAsleep && !screenCovered && !gameInFront && !screenOff && !(stopOnBattery && onBattery)
    }
}

/// Se fiamme e lampadine di Decora e le Luci in alto si muovono: ferme a batteria, con Riduci movimento, con i giochi
/// in pausa, con un videogioco davanti (SBU-193) e con gli schermi a riposo (QA SBU-231).
nonisolated struct DecorGate {
    var onBattery: Bool
    var reduceMotion: Bool
    var paused: Bool
    var gameInFront: Bool
    var displaysAsleep: Bool

    var animates: Bool { !onBattery && !reduceMotion && !paused && !gameInFront && !displaysAsleep }
}

/// «Segui la stagione»: l'effetto dei mesi dell'anno (emisfero nord), solo dal calendario, senza rete.
enum SeasonCalendar {
    static func effect(month: Int) -> String {
        switch month {
        case 3...5: Spring.id
        case 6...8: Summer.id
        case 9...11: Autumn.id
        default: Snow.id
        }
    }
}
