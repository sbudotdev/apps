import SwiftUI

/// What the study plan is ordered by, as in the original: date, grade or credits.
nonisolated enum PlanSort: String, CaseIterable, Identifiable, Sendable {
    case date
    case grade
    case credits

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .date: "Data"
        case .grade: "Voto"
        // Own key: "CFU" alone is also the unit after a number, lowercase "credits" in English.
        case .credits: LocalizedStringResource("Ordina per CFU", defaultValue: "CFU")
        }
    }
}
