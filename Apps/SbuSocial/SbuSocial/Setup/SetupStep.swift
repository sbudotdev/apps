import Foundation

/// The first-run setup, one thing to set per step, in this order (ADR-0021). Add or remove a
/// case to change the steps.
nonisolated enum SetupStep: Int, CaseIterable {
    case access, goal, intention, session, allowed, widget

    var title: LocalizedStringResource {
        switch self {
        case .access: "Tempo di utilizzo"
        case .goal: "Obiettivo giornaliero"
        case .intention: "Intenzioni"
        case .session: "Sessioni"
        case .allowed: "App consentite"
        case .widget: "Widget"
        }
    }

    /// What the step sets and why, in one or two sentences.
    var sentence: LocalizedStringResource {
        switch self {
        case .access: "Sbu Social copre le app con lo Schermo di Tempo di utilizzo. Serve il tuo permesso; i dati restano sul telefono."
        case .goal: "Quanto schermo ti dai in un giorno. Quando lo raggiungi arriva una notifica e il giorno non conta per la serie."
        case .intention: "Scegli l'app che ti distrae di più: la apri solo le volte che decidi, per i minuti che decidi."
        case .session: "Scegli un momento della giornata in cui tutte le app restano chiuse. Parte e finisce da solo."
        case .allowed: "Scegli le app che restano sempre aperte durante un blocco: telefono, mappe, quello che ti serve."
        case .widget: "Per avere la serie nella schermata Home: tieni premuto lo sfondo, tocca Modifica e aggiungi il widget di Sbu Social."
        }
    }

    var next: SetupStep? {
        SetupStep(rawValue: rawValue + 1)
    }
}
