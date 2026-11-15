import AppKit

/// Punto di ingresso: un'app "accessoria" (niente icona nel Dock),
/// controllata solo dall'icona ❄︎ nella barra dei menu.
@main
struct CozySnowApp {
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
