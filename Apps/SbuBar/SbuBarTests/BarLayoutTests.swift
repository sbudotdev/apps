@testable import SbuBar
import Foundation
import Testing

struct BarLayoutTests {
    let a = ItemID(bundleID: "com.example.a", name: "A")
    let b = ItemID(bundleID: "com.example.b", name: "B")
    let c = ItemID(bundleID: "com.example.c", name: "C")

    @Test func adoptPutsNewItemsInShownAndKeepsKnownOnes() {
        var layout = BarLayout(order: [.hidden: [b]])
        layout.adopt([a, b, c])
        #expect(layout.section(of: b) == .hidden)
        #expect(layout.order[.shown] == [a, c])
    }

    @Test func adoptKeepsTheSlotOfAnItemThatIsGone() {
        var layout = BarLayout(order: [.shown: [a, b, c]])
        layout.adopt([a, c])
        #expect(layout.order[.shown] == [a, b, c])
    }

    @Test func placeMovesAnItemBetweenSections() {
        var layout = BarLayout(order: [.shown: [a, b, c]])
        layout.place(b, in: .hidden, at: 0)
        #expect(layout.order[.shown] == [a, c])
        #expect(layout.order[.hidden] == [b])
    }

    @Test func noMovesWhenLiveMatchesLayout() {
        let layout = BarLayout(order: [.alwaysHidden: [c], .hidden: [b], .shown: [a]])
        #expect(layout.moves(from: [c, b, a]).isEmpty)
    }

    @Test func movesBringLiveOrderToLayout() {
        let layout = BarLayout(order: [.alwaysHidden: [c], .hidden: [b], .shown: [a]])
        let moves = layout.moves(from: [a, b, c])
        var live = [a, b, c]
        for move in moves {
            live.removeAll { $0 == move.item }
            let index = move.after.flatMap { live.firstIndex(of: $0) }.map { $0 + 1 } ?? 0
            live.insert(move.item, at: index)
        }
        #expect(live == [c, b, a])
    }

    @Test func movesIgnoreItemsThatAreNotLive() {
        let layout = BarLayout(order: [.hidden: [b], .shown: [a, c]])
        #expect(layout.moves(from: [a]).isEmpty)
    }

    @Test func duplicateItemInLiveDoesNotCrashAndReplaysToDesiredOrder() {
        let layout = BarLayout(order: [.alwaysHidden: [c], .hidden: [b], .shown: [a]])
        let moves = layout.moves(from: [a, b, a, c])
        var live = [a, b, a, c]
        for move in moves {
            live.removeAll { $0 == move.item }
            let index = move.after.flatMap { live.firstIndex(of: $0) }.map { $0 + 1 } ?? 0
            live.insert(move.item, at: index)
        }
        var seen = Set<ItemID>()
        let unique = live.filter { seen.insert($0).inserted }
        #expect(unique == [c, b, a])
    }

    @Test func duplicateItemInOrderDoesNotCrash() {
        let layout = BarLayout(order: [.hidden: [b], .shown: [a, b]])
        let moves = layout.moves(from: [a, b])
        #expect(moves == [Move(item: b, after: nil)])
    }

    @Test func placeClampsTheIndex() {
        var layout = BarLayout(order: [.shown: [a, b]])
        layout.place(c, in: .shown, at: -5)
        #expect(layout.order[.shown] == [c, a, b])
        layout.place(a, in: .shown, at: 99)
        #expect(layout.order[.shown] == [c, b, a])
    }

    @Test func placeWithinTheSameSectionCountsAfterRemoval() {
        var layout = BarLayout(order: [.shown: [a, b, c]])
        layout.place(a, in: .shown, at: 1)
        #expect(layout.order[.shown] == [b, a, c])
    }

    @Test func placeLeavesNoEmptySectionAndRoundTrips() throws {
        var layout = BarLayout(order: [.shown: [a]])
        layout.place(a, in: .hidden, at: 0)
        #expect(layout.order[.shown] == nil)
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let store = SettingsStore(directory: directory)
        try store.save(Settings(layout: layout))
        #expect(store.load().layout == layout)
    }

    @Test func sectionOfSearchesInVisualOrder() {
        let layout = BarLayout(order: [.shown: [a], .hidden: [a], .alwaysHidden: [a]])
        #expect(layout.section(of: a) == .alwaysHidden)
    }
}
