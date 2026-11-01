/// A turn through three graph nodes, for the banned-turn set.
nonisolated struct Turn: Sendable, Hashable {
    let from: Int
    let via: Int
    let to: Int
}
