import Foundation

private final class BundleToken {}

extension Bundle {
    /// Il bundle del nostro codice: l'app, oppure il salvaschermo (che gira dentro un processo di macOS,
    /// dove `Bundle.main` non è il nostro). Per le stringhe e gli sfondi che servono a tutti e due.
    nonisolated static let seasons = Bundle(for: BundleToken.self)
}
