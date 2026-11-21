import Foundation

extension ShortcutAction {
    var title: String {
        switch self {
        case .togglePlay: String(localized: "Avvia o metti in pausa")
        case .faster: String(localized: "Più veloce")
        case .slower: String(localized: "Più lento")
        case .previousCue: String(localized: "Sezione precedente")
        case .nextCue: String(localized: "Sezione successiva")
        case .returnFromCue: String(localized: "Torna dove eri")
        case .toggleVisibility: String(localized: "Mostra o nascondi")
        }
    }
}
