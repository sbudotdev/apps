import Observation

@Observable
final class ItemsModel {
    private let reader: any MenuBarReading
    private(set) var items: [MenuBarItem] = []

    init(reader: any MenuBarReading) { self.reader = reader }

    var liveOrder: [ItemID] { items.map(\.id) }

    func refresh() async {
        items = await reader.items().sorted { $0.frame.minX < $1.frame.minX }
    }
}
