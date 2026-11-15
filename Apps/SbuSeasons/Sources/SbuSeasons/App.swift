import AppKit

/// Punto di ingresso: un'app "accessoria" (niente icona nel Dock),
/// controllata solo dall'icona ❄︎ nella barra dei menu.
@main
struct SbuSeasonsApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
