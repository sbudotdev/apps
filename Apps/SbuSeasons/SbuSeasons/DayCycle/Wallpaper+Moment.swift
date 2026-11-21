import AppKit
import CoreImage

extension Wallpaper {
    static func named(_ id: String) -> Wallpaper? { all.first { $0.id == id } }

    /// Lo sfondo consigliato per un effetto: quello che c'è già, se gli sta bene, se no il primo che lo consiglia.
    /// nil = nessuno sfondo consiglia questo effetto (estate, sereno): lo sfondo resta com'è.
    static func suggested(for seasonID: String, current: Wallpaper?) -> Wallpaper? {
        if let current, current.effect == seasonID { return current }
        return all.first { $0.effect == seasonID }
    }

    /// Il file del momento, pronto per la scrivania: mezzogiorno è la copia del disegno (`install`), gli altri
    /// si fanno con `DayTint` la prima volta e poi si riusano. Lento (un JPEG grande): mai sul main thread.
    // shortcut: un momento già fatto non si rifà se un aggiornamento cambia il disegno; se cambia un file, cambiargli nome.
    nonisolated static func prepare(_ source: URL, moment: DayMoment, in folder: URL) throws -> URL {
        let copy = try install(source, in: folder)
        guard let look = Tuning.momentLooks[moment], !look.isIdentity else { return copy }
        let rendered = folder.appending(path: "\(source.deletingPathExtension().lastPathComponent)-\(moment.rawValue).jpg")
        if !FileManager.default.fileExists(atPath: rendered.path) {
            try DayTint.render(copy, look: look, to: rendered)
        }
        return rendered
    }

    /// Lo sfondo di uno schermo è uno dei nostri (copia o momento)? Se l'utente ne ha messo un altro, non si tocca.
    nonisolated static func isOurs(_ url: URL?, folder: URL) -> Bool {
        url?.standardizedFileURL.path.hasPrefix(folder.standardizedFileURL.path + "/") ?? false
    }
}
