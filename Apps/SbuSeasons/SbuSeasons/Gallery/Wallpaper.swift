import AppKit

/// Uno sfondo della galleria: due file nel bundle (`<id>-16x10.jpg` e, per gli schermi ultrawide, `<id>-21x9.jpg`)
/// e l'effetto che gli sta bene sopra.
struct Wallpaper: Identifiable {
    let id: String
    let title: String
    /// L'id della stagione consigliata (`Seasons.named`).
    let effect: String

    static let all: [Wallpaper] = [
        Wallpaper(id: "01-prima-neve", title: String(localized: "Prima neve"), effect: Snow.id),
        Wallpaper(id: "02-baita-nel-bosco", title: String(localized: "Baita nel bosco"), effect: Meteors.id),
        Wallpaper(id: "03-lago-ghiacciato", title: String(localized: "Lago ghiacciato"), effect: Mist.id),
        Wallpaper(id: "04-funivia", title: String(localized: "Funivia"), effect: Clouds.id),
        Wallpaper(id: "05-vigilia-in-piazza", title: String(localized: "Vigilia in piazza"), effect: Snow.id),
        Wallpaper(id: "06-pioggia-di-marzo", title: String(localized: "Pioggia di marzo"), effect: Rain.id),
        Wallpaper(id: "07-ciliegi-in-fiore", title: String(localized: "Ciliegi in fiore"), effect: Spring.id),
        Wallpaper(id: "08-sera-di-luglio", title: String(localized: "Sera di luglio"), effect: Fireflies.id),
        Wallpaper(id: "09-temporale-sul-lago", title: String(localized: "Temporale sul lago"), effect: Storm.id),
        Wallpaper(id: "10-larici-di-ottobre", title: String(localized: "Larici di ottobre"), effect: Autumn.id),
    ]

    /// 16:10 è 1,6 e 21:9 è 2,33: da 2 in su lo schermo è ultrawide e prende il file largo.
    func fileName(for screen: CGSize) -> String {
        id + (screen.width / screen.height >= 2 ? "-21x9" : "-16x10")
    }

    func url(for screen: CGSize, in bundle: Bundle = .main) -> URL? {
        bundle.url(forResource: fileName(for: screen), withExtension: "jpg")
    }

    /// macOS tiene il percorso dello sfondo, non l'immagine: una copia in Application Support resta valida
    /// anche se l'app si sposta, si aggiorna o parte da una cartella temporanea (Gatekeeper).
    static func install(_ source: URL, in folder: URL = installFolder) throws -> URL {
        let copy = folder.appending(path: source.lastPathComponent)
        let files = FileManager.default
        guard !files.contentsEqual(atPath: copy.path, andPath: source.path) else { return copy }
        // Una copia diversa viene da una versione vecchia dell'app: si sostituisce.
        if files.fileExists(atPath: copy.path) { try files.removeItem(at: copy) }
        try files.createDirectory(at: folder, withIntermediateDirectories: true)
        try files.copyItem(at: source, to: copy)
        return copy
    }

    static var installFolder: URL {
        URL.applicationSupportDirectory.appending(path: "Sbu Seasons/Wallpapers")
    }

    /// Mette lo sfondo su uno schermo, ricordando quello che c'era la prima volta.
    static func set(_ wallpaper: Wallpaper, on screen: NSScreen, memory: WallpaperMemory = WallpaperMemory()) throws {
        guard let source = wallpaper.url(for: screen.frame.size) else { return }
        if let current = NSWorkspace.shared.desktopImageURL(for: screen), !current.path.hasPrefix(installFolder.path) {
            memory.remember(current, screen: screen.wallpaperKey)
        }
        try NSWorkspace.shared.setDesktopImageURL(try install(source), for: screen)
    }

    /// "Lascia il mio schermo com'è": torna lo sfondo che c'era prima della galleria.
    static func restore(on screen: NSScreen, memory: WallpaperMemory = WallpaperMemory()) throws {
        guard let original = memory.original(screen: screen.wallpaperKey) else { return }
        try NSWorkspace.shared.setDesktopImageURL(original, for: screen)
        memory.forget(screen: screen.wallpaperKey)
    }
}

extension NSScreen {
    /// Un id stabile dello schermo: due monitor dello stesso modello hanno lo stesso `localizedName`.
    var wallpaperKey: String {
        let id = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID ?? 0
        guard let uuid = CGDisplayCreateUUIDFromDisplayID(id)?.takeRetainedValue() else { return "\(id)" }
        return CFUUIDCreateString(nil, uuid) as String
    }
}
