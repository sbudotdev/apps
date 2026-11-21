import CoreGraphics
import Foundation

/// Babbo Natale per tutti gli schermi insieme (SBU-114): un passaggio alla volta, che attraversa gli schermi uno dopo
/// l'altro (`ScreenRoute`) e ripassa da solo a intervalli casuali. Tiene anche "Metti in pausa i giochi": così la pausa
/// resta quando le scene si ricreano (un monitor collegato, il Mac che si risveglia).
final class Passages {
    /// Le scene, una per schermo. Quelle nuove prendono la pausa; un passaggio in volo sulle vecchie finisce.
    var scenes: [SeasonScene] = [] {
        didSet {
            flight = nil
            for scene in scenes {
                scene.toysPaused = paused
                scene.onSantaLeft = { [weak self, weak scene] altitude in
                    guard let self, let scene else { return }
                    self.santaLeft(scene, at: altitude)
                }
            }
        }
    }

    /// "Metti in pausa i giochi": i giochi stanno fermi, la slitta in volo sparisce e non parte niente finché non si toglie.
    var paused = false {
        didSet {
            scenes.forEach { $0.toysPaused = paused }
            flight = nil
            next = nil
        }
    }

    /// Acceso da "Fai passare Babbo Natale": da lì ripassa da solo ogni `Tuning.santaLoopInterval`, anche fuori
    /// dal periodo di Natale, fino al cambio di stagione. Senza, passa da solo solo dal 1° dicembre al 6 gennaio.
    private(set) var looping = false

    /// Il passaggio in corso: gli schermi in ordine, a che punto è, se e dove lascia il regalo.
    private var flight: (route: [Int], leg: Int, heading: CGFloat, carries: Bool, giftLeg: Int)?
    /// Quando ripassa (secondi dell'orologio di `tick`).
    private var next: TimeInterval?
    private let random: () -> Double
    /// "Babbo Natale passa da solo" (Impostazioni → Visitatori, SBU-187), acceso all'inizio. Dal menu passa sempre.
    static let autoKey = "santaVisits"
    var passesAlone: () -> Bool = { UserDefaults.standard.object(forKey: Passages.autoKey) as? Bool ?? true }
    /// Quanto spesso passa da solo; il giro chiamato dal menu tiene il suo ritmo.
    var frequency: () -> VisitFrequency = { VisitFrequency.saved }

    /// `random` in 0..<1: i test lo fissano.
    init(random: @escaping () -> Double = { .random(in: 0..<1) }) {
        self.random = random
    }

    var isFlying: Bool { flight != nil }

    /// Un intervallo a caso dentro `range`, con `roll` in 0..<1.
    nonisolated static func delay(in range: ClosedRange<CGFloat>, roll: Double) -> TimeInterval {
        Double(range.lowerBound) + Double(range.upperBound - range.lowerBound) * roll
    }

    private func delay(_ range: ClosedRange<CGFloat>) -> TimeInterval { Self.delay(in: range, roll: random()) }

    /// Fa partire un passaggio (`manual`: dal menu, e accende il loop). false = in pausa, già in volo o non è inverno.
    @discardableResult
    func send(at now: TimeInterval, manual: Bool = true) -> Bool {
        endStuckFlight()
        guard !paused, flight == nil, let lead = scenes.first, lead.season is Snow else { return false }
        let heading: CGFloat = random() < 0.5 ? -1 : 1
        let route = ScreenRoute.order(scenes.map(\.screenFrame), heading: heading, live: scenes.map(\.effectRuns))
        guard !route.isEmpty else { return false }
        if manual {
            looping = true
            next = now + delay(Tuning.santaLoopInterval)
        }
        let clock = lead.christmas
        let canGive = clock.diary.canGive(on: clock.now())
        let carries = manual ? canGive : SantaVisits.carriesGift(eve: clock.isEve, canGive: canGive, roll: random())
        flight = (route, 0, heading, carries, min(Int(random() * Double(route.count)), route.count - 1))
        SoundBoard.shared.play("babbo-natale")
        fly(enteringAt: nil)
        return true
    }

    /// Ogni tanto (`AppDelegate`, mentre l'effetto è acceso): è ora di ripassare?
    func tick(at now: TimeInterval) {
        endStuckFlight()
        guard !paused, flight == nil, let lead = scenes.first, lead.season is Snow else { return }
        guard looping || passesAlone() else { return }
        let frequency = frequency()
        guard let next else {
            self.next = now + delay(looping ? Tuning.santaLoopInterval : frequency.scaled(Tuning.santaFirstVisit))
            return
        }
        guard now >= next else { return }
        // La data si guarda solo all'ora del passaggio: niente calendario a ogni controllo.
        let clock = lead.christmas
        if looping || clock.isChristmasTime { send(at: now, manual: false) }
        self.next = now + delay(looping ? Tuning.santaLoopInterval
                                        : frequency.scaled(clock.isEve ? Tuning.santaEveInterval : Tuning.santaInterval))
    }

    /// Cambiando stagione finiscono il loop e la pausa (fuori dall'inverno la voce della pausa è spenta, QA SBU-63).
    func seasonChanged() {
        looping = false
        paused = false
    }

    /// La slitta entra nello schermo della tappa attuale, alla quota globale `y` se lo schermo la copre.
    /// Con Riduci movimento non vola: le tappe passano subito (il regalo cade dritto dove sarebbe arrivato).
    private func fly(enteringAt y: CGFloat?) {
        var y = y
        while var current = flight, current.leg < current.route.count {
            let scene = scenes[current.route[current.leg]]
            let band = scene.flightBand
            let altitude = y.flatMap { ScreenRoute.entry($0, into: band, margin: Self.margin) }
            let santa = scene.sendSanta(heading: current.heading, altitude: altitude,
                                        carriesGift: current.carries && current.leg == current.giftLeg)
            if scene.santa != nil { return }   // in volo: all'uscita la scena chiama `santaLeft`
            y = santa.map { band.minY + $0.altitude }
            current.leg += 1
            flight = current
        }
        flight = nil
    }

    /// La slitta è su uno schermo che si è fermato (pausa automatica, scelta degli schermi): lì non arriverebbe
    /// mai in fondo, e Babbo Natale non ripasserebbe più (SBU-193).
    private func endStuckFlight() {
        guard let current = flight, scenes.indices.contains(current.route[current.leg]),
              !scenes[current.route[current.leg]].effectRuns else { return }
        flight = nil
    }

    /// Mezza slitta (18 pt) più l'ondeggiare (5 pt): entra solo dove ci sta tutta.
    private static let margin: CGFloat = 24

    private func santaLeft(_ scene: SeasonScene, at altitude: CGFloat) {
        guard var current = flight, scenes[current.route[current.leg]] === scene else { return }
        current.leg += 1
        flight = current
        fly(enteringAt: scene.flightBand.minY + altitude)
    }
}
