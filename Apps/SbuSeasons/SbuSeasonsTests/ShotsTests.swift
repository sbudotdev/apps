import AppKit
import Metal
import SpriteKit
import SwiftUI
import Testing
@testable import SbuSeasons

/// Le immagini e i fotogrammi per far approvare a Matteo colori e disegni (SBU-178), fatti fuori schermo: niente
/// finestre sullo schermo del Mac. Spenti di norma; si accendono con la cartella di destinazione:
/// `TEST_RUNNER_SBU_SHOTS=/tmp/shots xcodebuild test -scheme SbuSeasons -destination 'platform=macOS' -testLanguage it -only-testing:SbuSeasonsTests/ShotsTests`
/// I fotogrammi (`<nome>-0001.png`…) si montano in un video con ffmpeg.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["SBU_SHOTS"] != nil))
struct ShotsTests {
    private let folder = URL(fileURLWithPath: ProcessInfo.processInfo.environment["SBU_SHOTS"] ?? NSTemporaryDirectory())
    /// La scena è piccola (punti) e l'immagine il doppio (pixel): come su uno schermo Retina.
    private let size = CGSize(width: 480, height: 240)

    /// Una scena d'inverno sopra uno sfondo della galleria (in fondo, dietro tutto), con una finestra su cui posarsi.
    private func scene(windows: [WindowEdge] = []) -> (SeasonScene, SKView) {
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Snow())
        if let url = Bundle.main.url(forResource: "01-prima-neve-16x10", withExtension: "jpg"), let image = NSImage(contentsOf: url) {
            let wallpaper = SKSpriteNode(texture: SKTexture(image: image))
            wallpaper.anchorPoint = .zero
            wallpaper.size = CGSize(width: size.width, height: size.width / image.size.width * image.size.height)
            wallpaper.position = CGPoint(x: 0, y: size.height - wallpaper.size.height)
            wallpaper.zPosition = -10
            scene.addChild(wallpaper)
        }
        // Le finestre, disegnate solo per la foto (nell'app sono quelle vere del Mac).
        for window in windows {
            let box = SKShapeNode(rect: window.rect, cornerRadius: 8)
            box.fillColor = NSColor(white: 0.98, alpha: 1)
            box.strokeColor = NSColor(white: 0.75, alpha: 1)
            box.zPosition = -5
            scene.addChild(box)
        }
        let view = SKView(frame: CGRect(origin: .zero, size: size))
        view.presentScene(scene)   // per `didMove`: i fiocchi
        scene.scaleMode = .aspectFill
        scene.updateWindows(windows, dock: nil, ceiling: size.height - 12)
        return (scene, view)
    }

    private func run(_ scene: SeasonScene, from start: TimeInterval = 0, seconds: TimeInterval) {
        for i in 0...Int(seconds * 60) { scene.step(at: start + TimeInterval(i) / 60) }
    }

    private func save(_ scene: SeasonScene, _ view: SKView, as name: String) throws {
        try write(render(scene), as: name)
    }

    private static let device = MTLCreateSystemDefaultDevice()
    private static let queue = device?.makeCommandQueue()

    /// La scena disegnata al doppio dei punti, come su uno schermo Retina (`texture(from:)` dà solo 1×).
    private func render(_ scene: SKScene) throws -> CGImage {
        let device = try #require(Self.device)
        let renderer = SKRenderer(device: device)
        renderer.scene = scene
        let width = Int(scene.size.width * 2), height = Int(scene.size.height * 2)
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
        descriptor.usage = [.renderTarget, .shaderRead]
        let texture = try #require(device.makeTexture(descriptor: descriptor))
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].texture = texture
        pass.colorAttachments[0].loadAction = .clear
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
        pass.colorAttachments[0].storeAction = .store
        let commands = try #require(Self.queue?.makeCommandBuffer())
        renderer.render(withViewport: CGRect(x: 0, y: 0, width: width, height: height), commandBuffer: commands, renderPassDescriptor: pass)
        commands.commit()
        commands.waitUntilCompleted()
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        texture.getBytes(&pixels, bytesPerRow: width * 4, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
        let info = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        let context = try #require(CGContext(data: &pixels, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                                             space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: info.rawValue))
        return try #require(context.makeImage())
    }

    private func write(_ image: CGImage, as name: String) throws {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let png = try #require(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
        try png.write(to: folder.appending(path: "\(name).png"))
    }

    /// `seconds` di scena a 30 fotogrammi al secondo, uno ogni due passi.
    private func film(_ scene: SeasonScene, _ view: SKView, as name: String, seconds: TimeInterval, from start: TimeInterval = 0,
                      each: (Int) -> Void = { _ in }) throws {
        for frame in 0..<Int(seconds * 30) {
            each(frame)
            scene.step(at: start + TimeInterval(frame * 2) / 60)
            scene.step(at: start + TimeInterval(frame * 2 + 1) / 60)
            try write(render(scene), as: String(format: "%@-%04d", name, frame))
        }
    }

    // MARK: - Albero

    @Test func trees() throws {
        let (scene, view) = scene()
        let small = ChristmasTree(at: CGPoint(x: 90, y: 0))
        let tall = ChristmasTree(at: CGPoint(x: 250, y: 0))
        let bare = ChristmasTree(at: CGPoint(x: 400, y: 0))
        for tree in [small, tall, bare] { scene.add(tree) }
        for (kind, points) in [(DecorationKind.bauble, [(-14.0, 18.0), (10, 24), (-4, 36), (6, 52), (-8, 60), (16, 14)]),
                               (.lights, [(0, 28), (0, 46)]), (.candyCane, [(-18, 14), (12, 40), (-2, 64)]), (.star, [(0, 70)])] {
            for tree in [small, tall] {
                tree.look.hanging = kind
                for (x, y) in points { tree.look.hang(at: CGPoint(x: x, y: y)) }
            }
        }
        tall.look.grow(by: 2.2)
        tall.look.resize(tall.look.decorations.count - 2, by: 1.8)
        tall.look.turn(tall.look.decorations.count - 2, by: 0.6)
        run(scene, seconds: 1)
        try save(scene, view, as: "1-alberi")
    }

    @Test func treeGestures() throws {
        let (scene, view) = scene()
        let tree = ChristmasTree(at: CGPoint(x: 240, y: 0))
        scene.add(tree)
        run(scene, seconds: 0.5)
        let kinds: [DecorationKind] = [.bauble, .bauble, .lights, .candyCane, .bauble, .candyCane, .bauble, .star]
        let spots: [CGPoint] = [CGPoint(x: -12, y: 20), CGPoint(x: 10, y: 30), CGPoint(x: 0, y: 40), CGPoint(x: -6, y: 52),
                                CGPoint(x: 8, y: 56), CGPoint(x: 14, y: 16), CGPoint(x: -2, y: 64), CGPoint(x: 0, y: 70)]
        try film(scene, view, as: "2-albero-gesti", seconds: 9) { frame in
            // Un clic ogni mezzo secondo appende, poi cresce, poi una pallina si ingrandisce, gira e si trascina via.
            if frame % 15 == 0, frame / 15 < kinds.count {
                tree.look.hanging = kinds[frame / 15]
                tree.clicked(at: spots[frame / 15])
            }
            if (130..<190).contains(frame) { tree.resized(at: CGPoint(x: 26, y: 4), by: 1.012) }
            if (200..<225).contains(frame) { tree.look.resize(0, by: 1.03) }
            if (225..<250).contains(frame) { tree.look.turn(0, by: 0.05) }
            if frame == 255 { tree.look.drop(0, at: CGPoint(x: 80, y: 10)) }
        }
    }

    // MARK: - Pupazzo

    @Test func snowmen() throws {
        let (scene, view) = scene()
        var looks: [SnowmanLook] = []
        var a = SnowmanLook(); looks.append(a)
        a.hat = .topHat; a.scarf = .red; looks.append(a)
        var b = SnowmanLook(); b.balls = [.large, .medium, .small]; b.hat = .beanie; b.scarf = .green; b.nose = .coal; looks.append(b)
        var c = SnowmanLook(); c.balls = [.small, .small, .large]; c.buttons = false; c.hat = .topHat; looks.append(c)
        var d = SnowmanLook(); d.balls = [.large, .large, .large]; d.hat = .beanie; d.scarf = .red; d.nose = .none; looks.append(d)
        for (i, look) in looks.enumerated() {
            scene.add(Snowman(at: CGPoint(x: 70 + CGFloat(i) * 85, y: 0), look: look))
        }
        run(scene, seconds: 1)
        try save(scene, view, as: "3-pupazzi")
    }

    // MARK: - Visitatori

    @Test func yeti() throws {
        let window = WindowEdge(id: 1, rect: CGRect(x: 120, y: 40, width: 180, height: 90), visible: [120...300])
        let (scene, view) = scene(windows: [window])
        var look = SnowmanLook()
        look.hat = .topHat
        look.scarf = .red
        scene.add(Snowman(at: CGPoint(x: 200, y: 130), look: look))
        scene.add(Snowman(at: CGPoint(x: 420, y: 0)))
        scene.sendYeti(heading: 1)
        try film(scene, view, as: "4-yeti", seconds: 10) { frame in
            // Salta sulla finestra, prende il pupazzo col cilindro; al secondo 12 lo scacci con un clic: lo lascia e scappa.
            if frame == 7 * 30 { scene.yeti?.clicked() }
        }
    }

    @Test func train() throws {
        let (scene, view) = scene()
        scene.add(ChristmasTree(at: CGPoint(x: 330, y: 0)))
        let train = try #require(scene.sendTrain(heading: 1, carriesGift: false))
        train.dropX = 200
        try film(scene, view, as: "5-trenino", seconds: 7) { frame in
            // L'elfo ha lasciato il regalo: al secondo 5 lo apri, e una decorazione vola sull'albero.
            if frame == 5 * 30 { scene.toys.compactMap { $0 as? Gift }.first?.clicked() }
        }
    }

    /// Un pupazzo mandato (SBU-200): scritto in un file `.sbuseasons`, riletto, e il trenino lo porta in mezzo allo schermo.
    @Test func received() throws {
        var look = SnowmanLook()
        look.hat = .pirate
        look.scarf = .striped
        look.mittens = true
        let url = try ToyFile.snowman(look).write(in: folder.appending(path: "file"))
        guard case .snowman(let arrived) = try ToyFile(contentsOf: url) else { Issue.record(); return }
        let (scene, view) = scene()
        #expect(scene.receive(Snowman(at: .zero, look: arrived)))
        try film(scene, view, as: "15-ricevuto", seconds: 6)
    }

    @Test func letter() throws {
        let (scene, view) = scene()
        scene.mailLetter(from: CGPoint(x: 300, y: 60))
        try film(scene, view, as: "6-letterina", seconds: 6) { _ in
            // Le azioni SpriteKit (la busta che sale) le muove la SKView, che qui non disegna da sola.
            if let letter = scene.letter, letter.hasActions() {
                let top = (size.height - 12) * Tuning.santaAltitude - 6
                letter.position.y = min(letter.position.y + Tuning.letterRise / 30, top)
                if letter.position.y >= top - 0.01 { letter.removeAllActions() }   // la posizione è in Float
            }
        }
    }

    // MARK: - Secondo giro (SBU-187)

    @Test func wardrobe() throws {
        let (scene, view) = scene()
        var looks: [SnowmanLook] = []
        var a = SnowmanLook(); a.hat = .cowboy; a.scarf = .striped; a.mittens = true; looks.append(a)
        var b = SnowmanLook(); b.hat = .party; b.eyes = .stars; b.bowTie = true; looks.append(b)
        var c = SnowmanLook(); c.hat = .elf; c.sweater = true; c.mittens = true; looks.append(c)
        var d = SnowmanLook(); d.hat = .pirate; d.cape = true; d.nose = .coal; looks.append(d)
        var e = SnowmanLook(); e.hat = .crown; e.cape = true; e.bowTie = true; e.balls = [.large, .medium, .small]; looks.append(e)
        var f = SnowmanLook(); f.hat = .antlers; f.scarf = .red; f.eyes = .stars; looks.append(f)
        for (i, look) in looks.enumerated() {
            scene.add(Snowman(at: CGPoint(x: 40 + CGFloat(i) * 62, y: 0), look: look))
        }
        let tree = ChristmasTree(at: CGPoint(x: 438, y: 0))
        tree.look.hanging = .angel
        tree.look.hang(at: CGPoint(x: 0, y: 40))
        tree.look.hanging = .bauble
        for (x, y) in [(-12.0, 20.0), (10, 28), (-4, 44), (6, 56)] { tree.look.hang(at: CGPoint(x: x, y: y)) }
        scene.add(tree)
        run(scene, seconds: 1)
        try save(scene, view, as: "11-vestiti-e-angelo")
    }

    @Test func livelySnowmen() throws {
        let window = WindowEdge(id: 1, rect: CGRect(x: 40, y: 60, width: 160, height: 80), visible: [40...200])
        let (scene, view) = scene(windows: [window])
        let rider = Snowman(at: CGPoint(x: 120, y: 140))
        scene.add(rider)
        scene.add(Snowman(at: CGPoint(x: 280, y: 0)))
        scene.add(Snowman(at: CGPoint(x: 400, y: 0)))
        try film(scene, view, as: "12-pupazzi-vivi", seconds: 9) { frame in
            // Scuoti la finestra: il pupazzo sopra salta. Poi due pupazzi si tirano una palla; uno lanciato forte si rompe;
            // lo Yeti arriva e una palla lo abbatte.
            if frame == 15 { scene.windowsShaken([window.id]) }
            if frame == 45 { scene.snowballFight() }
            if frame == 95 {
                rider.body.release(velocity: CGVector(dx: 600, dy: 900))
                rider.thrownHard = true
            }
            if frame == 140 { scene.sendYeti(heading: 1) }
            if frame == 185 {
                let ball = scene.makeSnowball(at: CGPoint(x: 460, y: 40))
                ball.body.release(velocity: CGVector(dx: -700, dy: 260))
            }
        }
    }

    @Test func elves() throws {
        let (scene, view) = scene()
        scene.sendElf(heading: 1, at: 180)
        try film(scene, view, as: "13-elfi", seconds: 9)
    }

    @Test func desk() throws {
        let size = CGSize(width: 520, height: 300)
        let board = NSView(frame: CGRect(origin: .zero, size: size))
        board.wantsLayer = true
        if let url = Bundle.main.url(forResource: "01-prima-neve-16x10", withExtension: "jpg"), let image = NSImage(contentsOf: url) {
            let wallpaper = NSImageView(frame: board.bounds)
            wallpaper.image = image
            wallpaper.imageScaling = .scaleAxesIndependently
            board.addSubview(wallpaper)
        }
        let items = [
            DeskItem(kind: .lights, screen: "A", start: CGPoint(x: 20, y: 280), end: CGPoint(x: 330, y: 270)),
            DeskItem(kind: .garland, screen: "A", center: CGPoint(x: 430, y: 262)),
            DeskItem(kind: .stocking, screen: "A", center: CGPoint(x: 60, y: 150), rotation: 0.15),
            DeskItem(kind: .candle, screen: "A", center: CGPoint(x: 140, y: 60)),
            DeskItem(kind: .bonfire, screen: "A", center: CGPoint(x: 240, y: 60), scale: 1.3),
            DeskItem(kind: .penguin, screen: "A", center: CGPoint(x: 350, y: 60), rotation: -0.2),
            DeskItem(kind: .snowGlobe, screen: "A", center: CGPoint(x: 450, y: 80), scale: 1.4),
            DeskItem(kind: .lights, screen: "A", start: CGPoint(x: 150, y: 200), end: CGPoint(x: 290, y: 150)),
        ]
        for item in items {
            let view = DeskItemView(item: item)
            view.frame = item.frame
            view.phase = 0.7
            board.addSubview(view)
        }
        let rep = try #require(board.bitmapImageRepForCachingDisplay(in: board.bounds))
        board.cacheDisplay(in: board.bounds, to: rep)
        try write(try #require(rep.cgImage), as: "14-decora")
    }

    // MARK: - Pioggia sul vetro

    /// Il cursore passa da sinistra a destra sul vetro bagnato (SBU-228): una foto della scia appena fatta, una a metà
    /// richiusura, e il filmato. In fondo, `pioggia-scia-ridotto`: con Riduci movimento, a metà la scia è ancora asciutta.
    @Test func rainWipe() throws {
        for calm in [false, true] {
            let (scene, view) = scene()
            scene.setSeason(Rain())
            scene.reduceMotion = calm
            var pointer = CGPoint(x: -100, y: -100)
            scene.pointerLocation = { pointer }
            run(scene, seconds: 12)   // il vetro si bagna
            let name = calm ? "pioggia-scia-ridotto" : "pioggia-scia"
            try film(scene, view, as: name, seconds: 5, from: 12) { frame in
                pointer = frame < 30 ? CGPoint(x: 40 + CGFloat(frame) * 13, y: 215 + sin(CGFloat(frame) / 5) * 10)
                                     : CGPoint(x: -100, y: -100)
            }
            try save(scene, view, as: name)
        }
    }

    // MARK: - Schede

    @Test func cards() throws {
        let tree = ChristmasTree(at: .zero)
        tree.clicked(at: CGPoint(x: 0, y: 30))
        tree.cardFocus = 0
        try card(SnowmanCard(look: SnowmanLook()) { _ in }, as: "7-scheda-pupazzo")
        try card(TreeCard(tree: tree, cut: {}), as: "8-scheda-albero")
        try card(LetterView(send: {}, cancel: {}), as: "9-letterina-finestra")
        try card(Form { VisitorsSection() }.formStyle(.grouped).frame(width: Quaderno.gridCell * 19).fixedSize(horizontal: false, vertical: true),
                 as: "10-impostazioni-visitatori")
        // Tre schermi, due spenti: l'ultimo acceso ha l'interruttore grigio (SBU-227).
        let before = Settings.shared.values
        defer { Settings.shared.values = before }
        Settings.shared.values.screensOff = ["B", "C"]
        try card(Form { ScreensSection(screens: [("Display Retina integrato", "A"), ("Studio Display", "B"), ("DELL U2723QE", "C")]) }
                    .formStyle(.grouped).frame(width: Quaderno.gridCell * 19).fixedSize(horizontal: false, vertical: true),
                 as: "11-impostazioni-schermi")
    }

    /// La scheda in italiano, chiara e scura.
    private func card(_ view: some View, as name: String) throws {
        for (appearance, suffix) in [(NSAppearance.Name.aqua, "chiaro"), (.darkAqua, "scuro")] {
            let host = NSHostingView(rootView: view.background(Quaderno.paper.color).environment(\.locale, Locale(identifier: "it")))
            host.appearance = NSAppearance(named: appearance)
            host.frame = CGRect(origin: .zero, size: host.fittingSize)
            let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            window.appearance = NSAppearance(named: appearance)
            window.contentView = host
            host.layoutSubtreeIfNeeded()
            let rep = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
            host.cacheDisplay(in: host.bounds, to: rep)
            try write(try #require(rep.cgImage), as: "\(name)-\(suffix)")
        }
    }
}
