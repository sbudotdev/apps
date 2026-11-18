import Foundation

/// Le pagine del tour di benvenuto, nell'ordine in cui si sfogliano.
nonisolated enum TourPage: Int, CaseIterable, Identifiable {
    case welcome, effects, toys, christmas, night, wallpapers

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: String(localized: "Ti diamo il benvenuto")
        case .effects: String(localized: "Undici effetti")
        case .toys: String(localized: "Giochi d'inverno")
        case .christmas: String(localized: "Natale")
        case .night: String(localized: "Notte")
        case .wallpapers: String(localized: "Sfondi")
        }
    }

    var text: String {
        switch self {
        case .welcome:
            String(localized: "Sul Mac cade la neve, o l'effetto che scegli. Si posa sulle finestre e sul Dock, e col cursore la sposti. Tutto parte dal menu ❄︎ in alto a destra.")
        case .effects:
            String(localized: "Neve, petali, foglie, lucciole, stelle cadenti, pioggia sul vetro, temporale, nebbia e nuvole. Li scegli dal menu ❄︎ → Effetto, con l'intensità subito sotto.")
        case .toys:
            String(localized: "Con la neve, dal menu ❄︎ → Giochi: lo spazzaneve, la pista da slittino, la funivia, un albero da decorare e i personaggi. Tieni premuto ⌥ sulla neve posata per fare una palla di neve.")
        case .christmas:
            String(localized: "Dal 1° dicembre al 6 gennaio Babbo Natale passa ogni tanto e lascia un regalo. Nel menu Natale ci sono anche l'omino di pan di zenzero e il conto alla rovescia.")
        case .night:
            String(localized: "Di sera lo schermo si scurisce un po' e in basso a destra si accende una candela. Scegli quando dal menu ❄︎ → Notte.")
        case .wallpapers:
            String(localized: "Dieci sfondi disegnati per Sbu Seasons, ognuno con il suo effetto. Se vuoi gli effetti solo sulla scrivania, accendi Dietro le finestre.")
        }
    }

    /// SF Symbol della pagina.
    var symbol: String {
        switch self {
        case .welcome: "snowflake"
        case .effects: "cloud.snow"
        case .toys: "figure.skiing.downhill"
        case .christmas: "gift"
        case .night: "moon.stars"
        case .wallpapers: "photo.on.rectangle"
        }
    }
}
