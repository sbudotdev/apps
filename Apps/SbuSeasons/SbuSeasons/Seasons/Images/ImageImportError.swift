import Foundation

/// Perché un'immagine non si è importata: il messaggio lo legge chi l'ha scelta.
nonisolated enum ImageImportError: LocalizedError, Equatable {
    case full, tooLarge, unreadable

    var errorDescription: String? {
        switch self {
        case .full: String(localized: "Hai già 10 immagini. Togline una per importarne un'altra.")
        case .tooLarge: String(localized: "L'immagine supera i 20 MB. Scegline una più leggera.")
        case .unreadable: String(localized: "Il file non si apre come immagine. Prova con un PNG, un JPEG, un HEIC o un SVG.")
        }
    }
}
