import CoreGraphics

/// Un tratto orizzontale su cui un oggetto può stare in piedi: il tratto scoperto del bordo di una finestra,
/// il Dock, il fondo dello schermo. Coordinate della scena.
nonisolated struct Ledge: Equatable {
    var y: CGFloat
    var span: ClosedRange<CGFloat>
}
