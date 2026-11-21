import AppKit

/// "Installa il salvaschermo": copia `Sbu Seasons.saver` dalle risorse dell'app in ~/Library/Screen Savers
/// e apre Impostazioni di Sistema → Salvaschermo, dove lo scegli tu. L'app non lo attiva mai da sola.
enum SaverInstaller {
    static var bundled: URL? { Bundle.main.url(forResource: "Sbu Seasons", withExtension: "saver") }

    static var folder: URL { URL.libraryDirectory.appending(path: "Screen Savers") }

    /// Copia il salvaschermo nella cartella, sostituendo quello di una versione precedente.
    static func install(_ source: URL, in folder: URL = folder) throws -> URL {
        let files = FileManager.default
        let destination = folder.appending(path: source.lastPathComponent)
        try files.createDirectory(at: folder, withIntermediateDirectories: true)
        if files.fileExists(atPath: destination.path) { try files.removeItem(at: destination) }
        try files.copyItem(at: source, to: destination)
        return destination
    }

    static func installAndOpenSettings() throws {
        guard let bundled else { throw CocoaError(.fileNoSuchFile) }
        _ = try install(bundled)
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.ScreenSaver-Settings.extension")!)
    }
}
