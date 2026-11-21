import CoreGraphics
import Foundation

/// Yeti e trenino per tutti gli schermi insieme (SBU-178), come Babbo Natale in `Passages` (SBU-114): un passaggio
/// alla volta per visitatore, che attraversa gli schermi uno dopo l'altro (`ScreenRoute`) e ripassa da solo a intervalli
/// casuali (`Passages.delay`). Lo Yeti passa da solo solo se c'è un pupazzo da portare via. La pausa è quella dei giochi:
/// le scene in pausa tolgono i visitatori (`SeasonScene.removeVisitors`) e qui non parte niente.
final class Visitors {
    var scenes: [SeasonScene] = [] {
        didSet {
            trips = [:]
            for scene in scenes {
                scene.onVisitorLeft = { [weak self, weak scene] kind, exit in
                    guard let self, let scene else { return }
                    self.left(scene, kind: kind, exit: exit)
                }
            }
        }
    }

    /// Il passaggio in corso di ogni visitatore: gli schermi in ordine, a che punto è, il pupazzo in spalla,
    /// su quale tappa il trenino lascia il regalo.
    private var trips: [VisitorKind: (route: [Int], leg: Int, heading: CGFloat, carrying: SnowmanLook?, giftLeg: Int)] = [:]
    /// Quando ripassa (secondi dell'orologio di `tick`).
    private var next: [VisitorKind: TimeInterval] = [:]
    private let random: () -> Double
    /// "Passa da solo" (Impostazioni → Visitatori), acceso all'inizio. I test lo fissano.
    var passesAlone: (VisitorKind) -> Bool = { UserDefaults.standard.object(forKey: $0.autoKey) as? Bool ?? true }
    /// Quanto spesso (Impostazioni → Visitatori). I test la fissano.
    var frequency: () -> VisitFrequency = { VisitFrequency.saved }

    /// `random` in 0..<1: i test lo fissano.
    init(random: @escaping () -> Double = { .random(in: 0..<1) }) {
        self.random = random
    }

    func isVisiting(_ kind: VisitorKind) -> Bool { trips[kind] != nil }

    private var canVisit: Bool {
        guard let lead = scenes.first else { return false }
        return lead.season is Snow && !lead.toysPaused
    }

    /// Fa partire un passaggio (dal menu o da `tick`). false = in pausa, già in giro o non è inverno.
    @discardableResult
    func send(_ kind: VisitorKind) -> Bool {
        guard canVisit else { return false }
        if let trip = trips[kind] {
            // In pausa o cambiando stagione la scena l'ha tolto: il viaggio è finito.
            // O lo schermo si è fermato con lui dentro (pausa automatica, scelta degli schermi): lì non va più avanti.
            let stop = trip.route[trip.leg]
            guard !scenes.indices.contains(stop) || !scenes[stop].isVisiting(kind) || !scenes[stop].effectRuns else { return false }
            trips[kind] = nil
        }
        let heading: CGFloat = random() < 0.5 ? -1 : 1
        let order = ScreenRoute.order(scenes.map(\.screenFrame), heading: heading, live: scenes.map(\.effectRuns))
        guard !order.isEmpty else { return false }
        // L'elfo fa il suo pupazzo su uno schermo solo.
        let route = kind == .elves ? Array(order.prefix(1)) : order
        trips[kind] = (route, 0, heading, nil, min(Int(random() * Double(route.count)), route.count - 1))
        go(kind)
        return true
    }

    /// Ogni tanto (`AppDelegate`, mentre l'effetto è acceso): è ora che qualcuno ripassi?
    func tick(at now: TimeInterval) {
        guard canVisit else { return }
        let frequency = frequency()
        for kind in VisitorKind.allCases where passesAlone(kind) {
            guard let due = next[kind] else {
                next[kind] = now + Passages.delay(in: frequency.scaled(kind.interval), roll: random())
                continue
            }
            guard now >= due else { continue }
            next[kind] = now + Passages.delay(in: frequency.scaled(kind.interval), roll: random())
            let hasSnowman = scenes.contains { $0.toys.contains { $0 is Snowman } }
            if kind != .yeti || hasSnowman { send(kind) }
        }
    }

    /// Cambiando stagione: niente viaggi a metà, e il conto riparte.
    func seasonChanged() {
        trips = [:]
        next = [:]
    }

    /// Il visitatore entra nello schermo della tappa attuale. Con Riduci movimento il trenino non corre:
    /// le tappe passano subito (il regalo cade dritto dove sarebbe arrivato).
    private func go(_ kind: VisitorKind) {
        while var trip = trips[kind], trip.leg < trip.route.count {
            let scene = scenes[trip.route[trip.leg]]
            switch kind {
            case .yeti: scene.sendYeti(heading: trip.heading, carrying: trip.carrying)
            case .train: scene.sendTrain(heading: trip.heading, carriesGift: trip.leg == trip.giftLeg)
            case .elves: scene.sendElf(heading: trip.heading)
            }
            if scene.isVisiting(kind) { return }   // in giro: all'uscita la scena chiama `left`
            trip.leg += 1
            trips[kind] = trip
        }
        trips[kind] = nil
    }

    private func left(_ scene: SeasonScene, kind: VisitorKind, exit: VisitorExit) {
        guard var trip = trips[kind], scenes[trip.route[trip.leg]] === scene else { return }
        // Scacciato, o uscito dalla parte da cui era venuto (è tornato indietro per un pupazzo): il giro finisce qui.
        guard !exit.fled, exit.heading == trip.heading else {
            trips[kind] = nil
            return
        }
        trip.carrying = exit.carrying
        trip.leg += 1
        trips[kind] = trip
        go(kind)
    }
}
