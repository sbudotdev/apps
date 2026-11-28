extension PadelMatch {
    /// For previews: 7-6 after a tie-break lost 5-7 by Loro, then 3-2 and 30-15 in the second set.
    static var preview: PadelMatch {
        var match = PadelMatch()
        let game: (Side) -> [Side] = { Array(repeating: $0, count: 4) }
        let sixAll = (0..<6).flatMap { _ in game(.us) + game(.them) }
        let tiebreak: [Side] = Array(repeating: .them, count: 5) + Array(repeating: .us, count: 7)
        let second = game(.us) + game(.them) + game(.us) + game(.them) + game(.us) + [.us, .us, .them]
        for side in sixAll + tiebreak + second { match.point(to: side) }
        return match
    }
}

extension PadelMatch {
    /// For previews: won 6-4 7-5.
    static var finishedPreview: PadelMatch {
        var match = PadelMatch()
        let game: (Side) -> [Side] = { Array(repeating: $0, count: 4) }
        let first = (0..<4).flatMap { _ in game(.us) + game(.them) } + game(.us) + game(.us)
        let second = (0..<5).flatMap { _ in game(.us) + game(.them) } + game(.us) + game(.us)
        for side in first + second { match.point(to: side) }
        return match
    }
}
