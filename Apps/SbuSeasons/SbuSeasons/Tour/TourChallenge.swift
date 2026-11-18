import Foundation

/// Le due cose da provare subito, in fondo a ogni pagina del tour: si spuntano quando le fai.
nonisolated enum TourChallenge: String, CaseIterable, Identifiable {
    case changeEffect, shakeGlobe

    var id: String { rawValue }

    var title: String {
        switch self {
        case .changeEffect: String(localized: "Scegli un altro effetto dal menu di Sbu Seasons")
        case .shakeGlobe: String(localized: "Scuoti il cursore: la neve posata si alza come in una palla di vetro")
        }
    }
}
