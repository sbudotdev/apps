/// L'elenco delle stagioni, nell'ordine del menu: una riga per stagione.
/// La prima è la scelta di partenza e quella usata se l'impostazione salvata non esiste più.
enum Seasons {
    static let all: [any Season] = [
        Snow(),
        Spring(),
        Dandelion(), SummerRain(), Fireflies(),
        Autumn(),
    ]

    static func named(_ id: String) -> any Season {
        all.first { $0.id == id } ?? all[0]
    }
}
