import Foundation

/// The tips of the day: one a day, in turn.
nonisolated enum Tips {
    static var all: [String] {
        [
            String(localized: "Tieni il telefono fuori dalla camera da letto: la sveglia la fa anche una sveglia."),
            String(localized: "Togli le notifiche delle app che apri per noia: resta quello che ti serve davvero."),
            String(localized: "Prima di aprire un'app chiediti cosa ci vai a fare. Se non lo sai, non aprirla."),
            String(localized: "Sposta le app che ti distraggono fuori dalla prima schermata."),
            String(localized: "A tavola il telefono resta in un'altra stanza."),
            String(localized: "Scegli un'ora al giorno senza schermo e tienila fissa."),
            String(localized: "Quando aspetti qualcosa, aspetta e basta: non serve riempire ogni minuto."),
        ]
    }

    static func text(for day: Day) -> String {
        let tips = all
        return tips[(day.ordinal % tips.count + tips.count) % tips.count]
    }
}
