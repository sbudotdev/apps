nonisolated struct BarLayout: Equatable, Sendable {
    var order: [BarSection: [ItemID]] = [:]

    private static let visualOrder: [BarSection] = [.alwaysHidden, .hidden, .shown]

    func section(of item: ItemID) -> BarSection? {
        Self.visualOrder.first { order[$0, default: []].contains(item) }
    }

    /// `index` counts positions after `item` has been removed from its old place.
    mutating func place(_ item: ItemID, in section: BarSection, at index: Int) {
        for key in BarSection.allCases {
            order[key]?.removeAll { $0 == item }
            if order[key]?.isEmpty == true { order[key] = nil }
        }
        var items = order[section, default: []]
        items.insert(item, at: min(max(index, 0), items.count))
        order[section] = items
    }

    mutating func adopt(_ live: [ItemID]) {
        for item in live where section(of: item) == nil {
            order[.shown, default: []].append(item)
        }
    }

    func moves(from live: [ItemID]) -> [Move] {
        var seenLive = Set<ItemID>()
        let live = live.filter { seenLive.insert($0).inserted }
        let present = Set(live)
        var placed = Set<ItemID>()
        let desired = Self.visualOrder.flatMap { order[$0, default: []] }
            .filter { present.contains($0) && placed.insert($0).inserted }
        let wanted = Set(desired)
        var current = live.filter(wanted.contains)
        var moves: [Move] = []
        for (index, item) in desired.enumerated() where current[index] != item {
            let after = index == 0 ? nil : desired[index - 1]
            moves.append(Move(item: item, after: after))
            current.removeAll { $0 == item }
            current.insert(item, at: index)
        }
        return moves
    }
}

// JSON object keyed by BarSection.rawValue, so the settings file stays readable and hand-editable.
extension BarLayout: Codable {
    init(from decoder: any Decoder) throws {
        let raw = try decoder.singleValueContainer().decode([String: [ItemID]].self)
        var seen = Set<ItemID>()
        for section in Self.visualOrder {
            let items = raw[section.rawValue, default: []].filter { seen.insert($0).inserted }
            if !items.isEmpty { order[section] = items }
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(Dictionary(uniqueKeysWithValues: order.map { ($0.key.rawValue, $0.value) }))
    }
}
