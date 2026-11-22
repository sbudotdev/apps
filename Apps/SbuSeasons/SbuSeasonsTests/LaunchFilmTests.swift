import AppKit
import Metal
import SpriteKit
import Testing
@testable import SbuSeasons

/// Il filmato del video di lancio (SBU-157), fatto fuori schermo con la scena vera: niente registrazione del Mac condiviso.
/// Spento di norma; si accende con la cartella che contiene `bg.png` (la scrivania, 1920×1080) e `cursor.png`:
/// `TEST_RUNNER_SBU_LAUNCH=/percorso xcodebuild test -scheme SbuSeasons -destination 'platform=macOS' -only-testing:SbuSeasonsTests/LaunchFilmTests`
/// Scrive `film/launch-0000.png`… a 30 fotogrammi al secondo, 15 secondi: si montano con ffmpeg.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["SBU_LAUNCH"] != nil))
struct LaunchFilmTests {
    private let folder = URL(fileURLWithPath: ProcessInfo.processInfo.environment["SBU_LAUNCH"] ?? NSTemporaryDirectory())
    /// Uno schermo da 960×540 punti disegnato al doppio, come un Retina: 1920×1080.
    private let size = CGSize(width: 960, height: 540)
    private let fps = 30
    /// Le stesse misure disegnate in `bg.png` (1 pt = 2 px): l'editor, il Dock, il fiocco nella barra dei menu.
    private let editor = CGRect(x: 80, y: 96, width: 800, height: 340)
    private let dock = CGRect(x: 410, y: 0, width: 140, height: 65)
    private let flake = CGPoint(x: 808, y: 528)
    private let ceiling: CGFloat = 516

    @Test func launch() throws {
        let out = folder.appending(path: "film")
        try FileManager.default.createDirectory(at: out, withIntermediateDirectories: true)
        let desk = try #require(NSImage(contentsOf: folder.appending(path: "bg.png")))
        let arrow = try #require(NSImage(contentsOf: folder.appending(path: "cursor.png")))

        // 0-3 s: solo la scrivania, la neve è spenta. Il cursore va al fiocco e clicca.
        let still = SKScene(size: size)
        still.addChild(wallpaper(desk))
        let stillCursor = cursor(arrow)
        let highlight = SKShapeNode(rect: CGRect(x: flake.x - 16, y: flake.y - 11, width: 32, height: 22), cornerRadius: 5)
        highlight.fillColor = NSColor(white: 1, alpha: 0.28)
        highlight.strokeColor = .clear
        highlight.zPosition = 5
        highlight.isHidden = true
        still.addChild(highlight)
        still.addChild(stillCursor)
        for frame in 0..<(3 * fps) {
            let t = Double(frame) / Double(fps)
            stillCursor.position = pointer(at: t)
            highlight.isHidden = t < 2.65
            try write(render(still), to: out, frame: frame)
        }

        // Valori che chiunque può scegliere nelle Impostazioni (Quantità «Forte», Dimensione, Velocità e mucchi alti),
        // perché la neve posata si veda da telefono. Nei test le impostazioni stanno in un dominio a parte.
        Settings.shared.values.flakeCount = Density.heavy.flakesPerReferenceScreen
        Settings.shared.values.flakeSize = 1.6
        Settings.shared.values.growth = 3
        Settings.shared.values.tallSnow = true

        // 3-15 s: Sbu Seasons accesa. La neve si posa sull'editor e sul Dock, il cursore la sposta, poi passa Babbo Natale.
        let scene = SeasonScene(size: size, screenOrigin: .zero, season: Snow())
        scene.addChild(wallpaper(desk))
        let view = SKView(frame: CGRect(origin: .zero, size: size))
        view.presentScene(scene)
        scene.scaleMode = .aspectFill
        let edge = WindowEdge(id: 1, rect: editor, visible: [editor.minX...editor.maxX], cornerRadius: 20)
        scene.updateWindows([edge], dock: dock, ceiling: ceiling)
        let liveCursor = cursor(arrow)
        scene.addChild(liveCursor)
        var now = CGPoint(x: -100, y: -100)
        scene.pointerLocation = { now }
        var santaSent = false
        for frame in (3 * fps)..<(15 * fps) {
            let t = Double(frame) / Double(fps)
            now = pointer(at: t)
            liveCursor.position = now
            if t >= 9.6, !santaSent { santaSent = scene.sendSanta(manual: true, heading: 1, carriesGift: false) != nil }
            let local = t - 3
            scene.step(at: local)
            scene.step(at: local + 1 / 60)
            try write(render(scene), to: out, frame: frame)
        }
        #expect(santaSent)
    }

    /// Dove sta il cursore (punti della scena) al secondo `t` del video.
    private func pointer(at t: Double) -> CGPoint {
        let rest = CGPoint(x: 720, y: 250)          // sull'editor, sotto la riga della chiave
        let ledgeY = editor.maxY + 6                // appena sopra il bordo dell'editor, dentro la neve posata
        let keys: [(Double, CGPoint)] = [
            (0, rest), (1.5, rest), (2.5, CGPoint(x: flake.x - 4, y: flake.y - 6)), (3.4, CGPoint(x: flake.x - 4, y: flake.y - 6)),
            (5.6, CGPoint(x: 140, y: ledgeY + 30)), (6.0, CGPoint(x: 150, y: ledgeY)), (8.6, CGPoint(x: 820, y: ledgeY)),
            (9.4, CGPoint(x: 640, y: 210)), (15, CGPoint(x: 600, y: 200)),
        ]
        guard let next = keys.firstIndex(where: { $0.0 > t }), next > 0 else { return keys.last!.1 }
        let (t0, a) = keys[next - 1], (t1, b) = keys[next]
        let u = (t - t0) / (t1 - t0)
        let e = u * u * (3 - 2 * u)                 // morbido in partenza e in arrivo
        return CGPoint(x: a.x + (b.x - a.x) * e, y: a.y + (b.y - a.y) * e)
    }

    private func wallpaper(_ image: NSImage) -> SKSpriteNode {
        let node = SKSpriteNode(texture: SKTexture(image: image), size: size)
        node.anchorPoint = .zero
        node.zPosition = -10
        return node
    }

    private func cursor(_ image: NSImage) -> SKSpriteNode {
        let node = SKSpriteNode(texture: SKTexture(image: image), size: CGSize(width: 32, height: 32))
        node.anchorPoint = CGPoint(x: 6.0 / 32, y: 1 - 3.0 / 32)   // la punta della freccia
        node.zPosition = 1000
        return node
    }

    private static let device = MTLCreateSystemDefaultDevice()
    private static let queue = device?.makeCommandQueue()

    /// Come `ShotsTests.render`: la scena al doppio dei punti, opaca.
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
        pass.colorAttachments[0].clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
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

    private func write(_ image: CGImage, to out: URL, frame: Int) throws {
        let png = try #require(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]))
        try png.write(to: out.appending(path: String(format: "launch-%04d.png", frame)))
    }
}
