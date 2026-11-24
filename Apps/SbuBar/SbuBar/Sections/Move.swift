/// `after == nil` means the far left of the whole managed sequence (the first always-hidden item).
nonisolated struct Move: Equatable, Sendable {
    let item: ItemID
    let after: ItemID?
}
