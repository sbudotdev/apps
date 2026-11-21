import CoreGraphics
import Foundation

/// Un oggetto da mandare a un amico (SBU-200): un file `.sbuseasons` con dentro JSON, lo stesso modello di `KeptToys`.
/// Va con AirDrop, Messaggi o Mail; chi lo apre se lo trova sulla scrivania. Niente rete: passa tutto dal file.
///
/// Il file arriva da fuori e non è fidato: si legge solo se è un file vero e piccolo (`Tuning.toyFileMaxBytes`),
/// la decodifica è rigida (un campo del tipo sbagliato o un vestito che non esiste e non si apre) e i numeri
/// tornano nei limiti dell'app (taglie, decorazioni, coordinate). Dentro ci sono solo dati: nessun percorso, nessun codice.
/// Della decorazione della scrivania non viaggiano lo schermo né la posizione di chi la manda.
nonisolated enum ToyFile: Equatable, Sendable {
    case snowman(SnowmanLook)
    case tree(TreeLook)
    case decoration(DeskItem)

    enum ReadError: Error, Equatable {
        case tooLarge, unreadable, newerVersion

        /// Perché non si apre, per chi ha fatto doppio clic.
        var explanation: String {
            switch self {
            case .tooLarge: String(localized: "È troppo grande per essere un oggetto di Sbu Seasons.")
            case .unreadable: String(localized: "Non è un oggetto di Sbu Seasons, oppure è rovinato.")
            case .newerVersion: String(localized: "L'ha fatto una versione più nuova di Sbu Seasons. Aggiorna l'app e riprova.")
            }
        }
    }

    static let format = "sbuseasons"
    /// Sale quando il formato cambia in un modo che una versione vecchia non capirebbe.
    static let version = 1
    static let fileExtension = "sbuseasons"
    /// Il tipo esportato in Info.plist.
    static let typeIdentifier = "dev.sbu.seasons.toy"

    // MARK: - Il JSON

    private struct Envelope: Codable {
        var format: String
        var version: Int
        var snowman: SnowmanLook?
        var tree: TreeLook?
        var decoration: Ornament?
    }

    /// La decorazione della scrivania senza schermo, posizione e id: solo com'è fatta.
    private struct Ornament: Codable {
        var kind: DeskItem.Kind
        var scale: CGFloat
        var rotation: CGFloat
        /// Le luci: da un'estremità all'altra.
        var span: CGVector
    }

    /// Legge un file ricevuto. Solo file veri e piccoli: niente cartelle, indirizzi web, pipe o file enormi.
    init(contentsOf url: URL) throws {
        guard url.isFileURL else { throw ReadError.unreadable }
        let values = try? url.resolvingSymlinksInPath().resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard values?.isRegularFile == true, let size = values?.fileSize else { throw ReadError.unreadable }
        guard size <= Tuning.toyFileMaxBytes else { throw ReadError.tooLarge }
        let handle: FileHandle
        do { handle = try FileHandle(forReadingFrom: url) } catch { throw ReadError.unreadable }
        defer { try? handle.close() }
        // Il file può crescere tra il controllo e la lettura: non si legge oltre il limite.
        guard let data = try? handle.read(upToCount: Tuning.toyFileMaxBytes + 1) else { throw ReadError.unreadable }
        guard data.count <= Tuning.toyFileMaxBytes else { throw ReadError.tooLarge }
        try self.init(data: data)
    }

    init(data: Data) throws {
        guard data.count <= Tuning.toyFileMaxBytes else { throw ReadError.tooLarge }
        guard let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
              envelope.format == Self.format, envelope.version >= 1 else { throw ReadError.unreadable }
        guard envelope.version <= Self.version else { throw ReadError.newerVersion }
        switch (envelope.snowman, envelope.tree, envelope.decoration) {
        case (let snowman?, nil, nil): self = .snowman(Self.limited(snowman))
        case (nil, let tree?, nil): self = .tree(Self.limited(tree))
        case (nil, nil, let ornament?): self = .decoration(Self.limited(ornament))
        default: throw ReadError.unreadable
        }
    }

    func data() throws -> Data {
        var envelope = Envelope(format: Self.format, version: Self.version)
        switch self {
        case .snowman(let look): envelope.snowman = look
        case .tree(let look): envelope.tree = look
        case .decoration(let item):
            envelope.decoration = Ornament(kind: item.kind, scale: item.scale, rotation: item.rotation,
                                           span: CGVector(dx: item.end.x - item.start.x, dy: item.end.y - item.start.y))
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(envelope)
    }

    /// Il nome del file, nella lingua di chi lo manda.
    var name: String {
        switch self {
        case .snowman: String(localized: "Pupazzo")
        case .tree: String(localized: "Albero di Natale")
        case .decoration(let item): item.kind.title
        }
    }

    /// Scrive il file in una cartella nuova dentro `folder` (così due file con lo stesso nome non si pestano).
    func write(in folder: URL) throws -> URL {
        let own = folder.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: own, withIntermediateDirectories: true)
        let url = own.appending(path: name).appendingPathExtension(Self.fileExtension)
        try data().write(to: url, options: .atomic)
        return url
    }

    // MARK: - Nei limiti

    /// `value` dentro `range`; un numero non finito diventa `fallback`.
    private static func clamp(_ value: CGFloat, _ range: ClosedRange<CGFloat>, fallback: CGFloat) -> CGFloat {
        value.isFinite ? min(max(value, range.lowerBound), range.upperBound) : fallback
    }

    private static func angle(_ radians: CGFloat) -> CGFloat {
        radians.isFinite ? radians.truncatingRemainder(dividingBy: 2 * .pi) : 0
    }

    private static func limited(_ look: SnowmanLook) -> SnowmanLook {
        var look = look
        look.balls = Array((look.balls + Array(repeating: .medium, count: 3)).prefix(3))
        return look
    }

    private static func limited(_ look: TreeLook) -> TreeLook {
        var look = look
        look.growth = clamp(look.growth, Tuning.treeGrowth, fallback: 1)
        let topper = look.decorations.last { $0.kind.isTopper }.map { Decoration(kind: $0.kind, position: TreeLook.tip, scale: $0.scale, rotation: $0.rotation) }
        let hanging = look.decorations.filter { !$0.kind.isTopper }.prefix(Tuning.maxDecorations)
        look.decorations = (Array(hanging) + (topper.map { [$0] } ?? [])).map { decoration in
            var d = decoration
            d.position = CGPoint(x: clamp(d.position.x, -TreeLook.halfWidth...TreeLook.halfWidth, fallback: 0),
                                 y: clamp(d.position.y, 0...TreeLook.tip.y, fallback: TreeLook.foliage.lowerBound))
            d.scale = clamp(d.scale, Tuning.decorationScale, fallback: 1)
            d.rotation = angle(d.rotation)
            d.color = min(max(d.color, 0), TreeLook.colorCount - 1)
            return d
        }
        return look
    }

    private static func limited(_ ornament: Ornament) -> DeskItem {
        let scale = clamp(ornament.scale, Tuning.deskScale, fallback: 1)
        guard ornament.kind == .lights else {
            return DeskItem(kind: ornament.kind, screen: "", center: .zero, scale: scale, rotation: angle(ornament.rotation))
        }
        let span = Tuning.toyFileMaxLightsSpan
        // Le luci vanno da sinistra a destra, come quando le metti tu.
        let dx = clamp(abs(ornament.span.dx), 0...span, fallback: DeskItem.Kind.lights.size.width)
        let dy = clamp(ornament.span.dx < 0 ? -ornament.span.dy : ornament.span.dy, -span...span, fallback: 0)
        var item = DeskItem(kind: .lights, screen: "", start: CGPoint(x: -dx / 2, y: -dy / 2), end: CGPoint(x: dx / 2, y: dy / 2))
        item.scale = scale
        return item
    }
}
