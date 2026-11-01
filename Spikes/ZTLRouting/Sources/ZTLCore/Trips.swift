public struct Trip: Sendable {
    public let name: String
    public let from: Point
    public let to: Point

    public init(name: String, from: Point, to: Point) {
        self.name = name
        self.from = from
        self.to = to
    }
}

let centrale = Point(45.4862, 9.2044), bocconi = Point(45.4490, 9.1900)
let duomoMI = Point(45.4642, 9.1900), brera = Point(45.4719, 9.1880), castello = Point(45.4705, 9.1794)
let campoMarte = Point(43.7833, 11.2825), novoli = Point(43.7960, 11.2190), duomoFI = Point(43.7731, 11.2560)
public let milanoTrips = [
    Trip(name: "Centrale-Porta Genova", from: centrale, to: Point(45.4533, 9.1680)),
    Trip(name: "Sempione-Porta Romana", from: Point(45.4790, 9.1690), to: Point(45.4490, 9.2030)),
    Trip(name: "Loreto-Bocconi", from: Point(45.4859, 9.2160), to: bocconi),
    Trip(name: "Lambrate-San Siro", from: Point(45.4847, 9.2365), to: Point(45.4781, 9.1240)),
    Trip(name: "Cinque Giornate-Conciliazione", from: Point(45.4626, 9.2120), to: Point(45.4671, 9.1635)),
    Trip(name: "Porta Venezia-Ticinese", from: Point(45.4765, 9.2085), to: Point(45.4495, 9.1815)),
    Trip(name: "Centrale-Duomo (arrivo dentro)", from: centrale, to: duomoMI),
    Trip(name: "Bocconi-Castello (arrivo dentro)", from: bocconi, to: castello),
    Trip(name: "Duomo-Centrale (partenza dentro)", from: duomoMI, to: centrale),
    Trip(name: "Brera-Bocconi (partenza dentro)", from: brera, to: bocconi),
]

public let firenzeTrips = [
    Trip(name: "Campo di Marte-Porta Romana", from: campoMarte, to: Point(43.7560, 11.2400)),
    Trip(name: "Dalmazia-Ferrucci", from: Point(43.7930, 11.2430), to: Point(43.7585, 11.2700)),
    Trip(name: "Le Cure-Soffiano", from: Point(43.7900, 11.2660), to: Point(43.7600, 11.2200)),
    Trip(name: "Novoli-Gavinana", from: novoli, to: Point(43.7550, 11.2750)),
    Trip(name: "Cascine-Beccaria", from: Point(43.7810, 11.2200), to: Point(43.7690, 11.2720)),
    Trip(name: "Libertà-San Frediano", from: Point(43.7860, 11.2620), to: Point(43.7710, 11.2300)),
    Trip(name: "Campo di Marte-Duomo (arrivo dentro)", from: campoMarte, to: duomoFI),
    Trip(name: "Novoli-Santa Croce (arrivo dentro)", from: novoli, to: Point(43.7686, 11.2622)),
    Trip(name: "Duomo-Novoli (partenza dentro)", from: duomoFI, to: novoli),
    Trip(name: "Santo Spirito-Campo di Marte (partenza dentro)", from: Point(43.7675, 11.2480), to: campoMarte),
]

