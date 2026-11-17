import CoreGraphics

/// Che cosa è stato scosso.
nonisolated enum Shake: Equatable {
    case pointer
    case window(CGWindowID)
}
