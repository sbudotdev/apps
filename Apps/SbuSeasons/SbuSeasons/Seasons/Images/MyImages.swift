import AppKit
import SpriteKit

/// Le tue immagini (SBU-230): fino a 10 immagini importate nelle Impostazioni cadono al posto dei fiocchi,
/// come la neve, come le foglie o come la pioggia. Non si posano. Senza immagini, l'invito a importarle.
struct MyImages: Season {
    static let id = "images"
    var id: String { Self.id }
    var title: String { String(localized: "Le tue immagini") }
    let symbol = "photo.on.rectangle"
    var pileColor: NSColor { .white }
    var settles: Bool { false }
    var library = ImageLibrary.shared

    private var textures: [SKTexture] { library.textures(skipping: Settings.shared.values.imagesOff) }
    private var motion: ImageMotion { Settings.shared.values.imagesMotion }

    var abundance: Double { textures.isEmpty ? 0 : Tuning.imagesAbundance }
    var invitation: String? {
        textures.isEmpty ? String(localized: "Importa le tue immagini in Impostazioni → Le tue immagini.") : nil
    }
    var revision: Int {
        var hasher = Hasher()
        hasher.combine(library.revision)
        hasher.combine(Settings.shared.values.imagesOff)
        hasher.combine(motion)
        return hasher.finalize()
    }

    /// Ogni particella ha la sua immagine (`Particle.texture`): questa non si vede mai.
    func makeTexture() -> SKTexture { SKTexture() }

    func particle(depth: CGFloat) -> Particle {
        Self.particle(depth: depth, motion: motion, texture: textures.randomElement())
    }

    static func particle(depth: CGFloat, motion: ImageMotion, texture: SKTexture?) -> Particle {
        let radius = Tuning.imageRadius + depth * Tuning.imageRadiusDepth
        let alpha = Tuning.imageOpacity.lowerBound + depth * (Tuning.imageOpacity.upperBound - Tuning.imageOpacity.lowerBound)
        var particle: Particle
        switch motion {
        case .snow:
            particle = Particle(radius: radius, alpha: alpha, fallSpeed: 22 + depth * 58,
                                swayAmplitude: .random(in: 8...26), swayFrequency: .random(in: 0.3...0.9))
        case .leaves:
            // Come le foglie d'autunno: planano larghe, girano e si ribaltano.
            particle = Particle(radius: radius, alpha: alpha, fallSpeed: 16 + depth * 34,
                                swayAmplitude: .random(in: AutumnTuning.sway), swayFrequency: .random(in: 0.15...0.4),
                                spin: .random(in: AutumnTuning.spin) * (Bool.random() ? 1 : -1),
                                flip: .random(in: AutumnTuning.flip))
        case .rain:
            particle = Particle(radius: radius, alpha: alpha,
                                fallSpeed: .random(in: Tuning.imageRainSpeed) * (0.7 + depth * 0.3),
                                swayAmplitude: 0, swayFrequency: 0)
        }
        particle.texture = texture
        return particle
    }
}
