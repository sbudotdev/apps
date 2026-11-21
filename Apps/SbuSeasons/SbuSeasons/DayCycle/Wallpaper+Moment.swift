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

    /// «Giorno e notte» fatto da macOS: l'HEIC con gli otto momenti (`DynamicWallpaper`), fatto la prima volta e poi riusato.
    // shortcut: come `prepare(_:moment:in:)`, un file già fatto non si rifà se cambia il disegno o `momentLooks`; cambiargli nome.
    nonisolated static func prepareDynamic(_ source: URL, in folder: URL) throws -> URL {
        let file = folder.appending(path: "\(source.deletingPathExtension().lastPathComponent)-giorno-e-notte.heic")
        if !FileManager.default.fileExists(atPath: file.path) {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try DynamicWallpaper.render(source, to: file)
        }
        return file
    }

    /// Il file per la scelta: «Segue l'ora del Mac» è l'HEIC dinamico, un momento fisso il suo JPEG.
    nonisolated static func prepare(_ source: URL, choice: MomentChoice, at date: Date, in folder: URL) throws -> URL {
        if choice == .automatic { return try prepareDynamic(source, in: folder) }
        return try prepare(source, moment: choice.moment(at: date), in: folder)
    }

    /// macOS ha perso lo sfondo (cambio di schermo, risveglio, aggiornamento)? Solo se c'era uno dei nostri e adesso
    /// c'è uno sfondo di sistema o niente: un'immagine scelta dall'utente non si tocca.
    // shortcut: un utente che sceglie proprio uno sfondo di sistema lo ritrova nostro al cambio di schermo seguente; se capita, ascoltare i cambi di sfondo.
    nonisolated static func wasLost(placed: URL?, current: URL?, folder: URL) -> Bool {
        guard isOurs(placed, folder: folder), !isOurs(current, folder: folder) else { return false }
        guard let path = current?.standardizedFileURL.path else { return true }
        return ["/System/Library/Desktop Pictures/", "/System/Library/Wallpapers/", "/Library/Desktop Pictures/"].contains { path.hasPrefix($0) }
    }

    /// Lo sfondo di uno schermo è uno dei nostri (copia o momento)? Se l'utente ne ha messo un altro, non si tocca.
    nonisolated static func isOurs(_ url: URL?, folder: URL) -> Bool {
        url?.standardizedFileURL.path.hasPrefix(folder.standardizedFileURL.path + "/") ?? false
    }
}
