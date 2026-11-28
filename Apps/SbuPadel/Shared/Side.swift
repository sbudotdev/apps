/// One of the two pairs on court: the person wearing the watch plays with `us`.
nonisolated enum Side: String, Codable, Sendable, CaseIterable {
    case us
    case them

    var other: Side { self == .us ? .them : .us }
}
