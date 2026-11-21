import CoreGraphics

/// Come cambia uno sfondo in un momento del giorno: luce, colore e un velo di cielo che sfuma dall'alto.
/// I valori per momento sono in `Tuning.momentLooks`.
nonisolated struct MomentLook: Sendable, Equatable {
    /// Più luce o meno, in stop (0 = com'è, -1 = metà luce).
    var exposure: CGFloat = 0
    /// La temperatura della luce in kelvin: sotto 6500 più calda, sopra più fredda.
    var temperature: CGFloat = 6500
    /// 1 = colori com'è, 0 = grigio.
    var saturation: CGFloat = 1
    var contrast: CGFloat = 1
    /// Il velo: colore sRGB (0…1) in cima, che sfuma fino a `veilReach` dell'altezza (1 = tutto lo schermo).
    var veil: (red: CGFloat, green: CGFloat, blue: CGFloat) = (0, 0, 0)
    var veilOpacity: CGFloat = 0
    var veilReach: CGFloat = 1

    static func == (a: MomentLook, b: MomentLook) -> Bool {
        a.exposure == b.exposure && a.temperature == b.temperature && a.saturation == b.saturation
            && a.contrast == b.contrast && a.veilOpacity == b.veilOpacity && a.veilReach == b.veilReach
            && a.veil.red == b.veil.red && a.veil.green == b.veil.green && a.veil.blue == b.veil.blue
    }

    /// Mezzogiorno: lo sfondo così com'è disegnato.
    var isIdentity: Bool { self == MomentLook() }
}
