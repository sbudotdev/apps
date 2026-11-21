import AppKit

/// Punto di ingresso: un'app "accessoria" (niente icona nel Dock),
/// controllata solo dall'icona ❄︎ nella barra dei menu.
@main
struct SbuSeasonsApp {
    /// Il nome visibile, da CFBundleDisplayName in project.yml: per rinominare l'app basta cambiare lì.
    static let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "Sbu Seasons"
    /// La versione (`MARKETING_VERSION`): «Novità» mostra le righe della sua.
    static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""

    @MainActor
    static func main() {
        let app = NSApplication.shared
        // Durante i test l'app fa solo da host: niente neve, finestre o richieste di permessi.
        let isTestHost = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let delegate = isTestHost ? nil : AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
