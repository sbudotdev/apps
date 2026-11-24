@testable import SbuBar
import ApplicationServices
import CoreGraphics
import Testing

struct FakeReader: MenuBarReading {
    let result: [MenuBarItem]
    func items() async -> [MenuBarItem] { result }
}

@MainActor
struct ItemsModelTests {
    let wifi = MenuBarItem(id: ItemID(bundleID: "com.apple.controlcenter", name: "WiFi"), title: "Wi-Fi", frame: CGRect(x: 900, y: 0, width: 24, height: 24))
    let app = MenuBarItem(id: ItemID(bundleID: "com.example.app", name: "Item-0"), title: "App", frame: CGRect(x: 800, y: 0, width: 24, height: 24))

    @Test func refreshPublishesItemsInLeftToRightOrder() async {
        let model = ItemsModel(reader: FakeReader(result: [wifi, app]))
        await model.refresh()
        #expect(model.liveOrder == [app.id, wifi.id])
    }

    @Test func refreshWithNoItemsIsEmpty() async {
        let model = ItemsModel(reader: FakeReader(result: []))
        await model.refresh()
        #expect(model.items.isEmpty)
    }
}

struct SystemMenuBarReaderTests {
    @Test func identifierWinsElseItemIndex() {
        #expect(SystemMenuBarReader.names(identifiers: ["id.wifi", "", nil]) == ["id.wifi", "Item-1", "Item-2"])
    }

    @Test func repeatedIdentifiersGetIndexSuffix() {
        #expect(SystemMenuBarReader.names(identifiers: ["A", "A", "A"]) == ["A", "A-1", "A-2"])
    }

    @Test func suffixedNamesStayUnique() {
        let names = SystemMenuBarReader.names(identifiers: ["A", "A-2", "A"])
        #expect(Set(names).count == 3)
        #expect(names.first == "A" && names[1] == "A-2")
    }

    @Test(.enabled(if: AXIsProcessTrusted())) func realReaderListsSortedItems() async {
        let items = await SystemMenuBarReader().items().sorted { $0.frame.minX < $1.frame.minX }
        #expect(!items.isEmpty)
    }
}
