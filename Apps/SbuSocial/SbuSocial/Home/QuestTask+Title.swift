import Foundation

extension QuestTask {
    var title: LocalizedStringResource {
        switch self {
        case .review: "Rivedi ieri"
        case .tip: "Leggi il consiglio di oggi"
        case .block: "Finisci un blocco"
        }
    }
}
