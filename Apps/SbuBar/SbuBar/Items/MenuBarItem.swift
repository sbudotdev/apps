import CoreGraphics

nonisolated struct MenuBarItem: Identifiable, Equatable, Sendable {
    let id: ItemID
    let title: String
    let frame: CGRect
}
