/// A count for each side: points, games or sets.
nonisolated struct Pair: Equatable, Sendable {
    var us = 0
    var them = 0

    subscript(side: Side) -> Int {
        get { side == .us ? us : them }
        set { if side == .us { us = newValue } else { them = newValue } }
    }
}
