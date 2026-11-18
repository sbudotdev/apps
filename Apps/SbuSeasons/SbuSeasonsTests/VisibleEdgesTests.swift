import Testing
import CoreGraphics
@testable import SbuSeasons

@Test func frontWindowHidesPartOfTheEdgeBehind() {
    let back = (id: CGWindowID(1), rect: CGRect(x: 0, y: 0, width: 400, height: 300))       // bordo a y=300
    let front = (id: CGWindowID(2), rect: CGRect(x: 100, y: 200, width: 100, height: 200))  // copre x 100…200
    let away = (id: CGWindowID(3), rect: CGRect(x: 250, y: 0, width: 50, height: 100))      // sopra l'area di "back"

    let edges = visibleTopEdges([front, away, back], clearance: 16)

    #expect(edges[0].visible == [100...200])           // la finestra davanti è libera
    #expect(edges[2].visible == [0...100, 200...250, 300...400])  // dietro: buchi dove ci sono quelle davanti
    #expect(edges[1].visible == [250...300])           // "away" prende la neve della sua colonna (MGS-628)
}

@Test func windowInFrontButEntirelyBelowLeavesTheEdgeAlone() {
    let back = (id: CGWindowID(1), rect: CGRect(x: 0, y: 500, width: 400, height: 300))
    let below = (id: CGWindowID(2), rect: CGRect(x: 100, y: 0, width: 100, height: 400))   // non tocca "back"
    #expect(visibleTopEdges([below, back], clearance: 16)[1].visible == [0...400])
}

@Test func windowJustAboveTheEdgeCoversTheSnow() {
    let back = (id: CGWindowID(1), rect: CGRect(x: 0, y: 0, width: 100, height: 100))
    let hovering = (id: CGWindowID(2), rect: CGRect(x: -10, y: 105, width: 200, height: 50)) // 5pt sopra il bordo
    #expect(visibleTopEdges([hovering, back], clearance: 16)[1].visible.isEmpty)
}

@Test func clearanceFollowsTheMaximumPileHeight() {
    let back = (id: CGWindowID(1), rect: CGRect(x: 0, y: 0, width: 100, height: 100))
    let hovering = (id: CGWindowID(2), rect: CGRect(x: -10, y: 130, width: 200, height: 50)) // 30 pt sopra il bordo
    #expect(visibleTopEdges([hovering, back], clearance: 40)[1].visible.isEmpty)
    #expect(visibleTopEdges([hovering, back], clearance: 16)[1].visible == [0...100])
}

// Schermo alto 1080, barra dei menu di 30 pt: la zona libera finisce a 1050 (dati veri, MGS-615).
// La neve non scende mai sotto il bordo: se il mucchio non ci sta sotto la barra, niente neve (SBU-101).
@Test(arguments: [
    (edgeTop: CGFloat(1000), expected: CGFloat?(1000)),  // c'è posto: la neve sta sul bordo
    (edgeTop: CGFloat(1034), expected: CGFloat?(1034)),  // il mucchio tocca appena la barra: sta sul bordo
    (edgeTop: CGFloat(1040), expected: nil),             // il mucchio entrerebbe nella barra: niente neve
    (edgeTop: CGFloat(1050), expected: nil),             // attaccata alla barra (ingrandita): niente neve
    (edgeTop: CGFloat(1080), expected: nil),             // schermo intero: niente neve
])
func snowNeverSitsBelowTheEdge(edgeTop: CGFloat, expected: CGFloat?) {
    #expect(pileBase(edgeTop: edgeTop, pileHeight: 16, ceiling: 1050) == expected)
}

// MARK: - Solo finestre vere (SBU-101)

private func window(_ id: CGWindowID, _ rect: CGRect, pid: pid_t = 1, standard: Bool? = nil) -> AppWindow {
    AppWindow(id: id, rect: rect, pid: pid, standard: standard)
}

@Test func accessibilityKeepsOnlyStandardWindows() {
    let main = window(1, CGRect(x: 0, y: 0, width: 800, height: 600), standard: true)
    let palette = window(2, CGRect(x: 200, y: 600, width: 400, height: 50), standard: false)  // anche fuori dalla principale
    #expect(systemWindows([palette, main]).map(\.id) == [1])
}

@Test func withoutAccessibilityAWindowInsideABiggerOneOfTheSameAppIsAModal() {
    let main = window(1, CGRect(x: 0, y: 0, width: 800, height: 600))
    let search = window(2, CGRect(x: 200, y: 300, width: 400, height: 200))     // davanti, tutta dentro
    let otherApp = window(3, CGRect(x: 250, y: 100, width: 100, height: 100), pid: 2)  // dentro, ma di un'altra app
    let beside = window(4, CGRect(x: 700, y: 100, width: 300, height: 100))      // stessa app, esce dai bordi
    #expect(systemWindows([search, otherApp, beside, main]).map(\.id) == [3, 4, 1])
}

@Test func theAnswerOfAccessibilityWinsOverTheFallbackRule() {
    let main = window(1, CGRect(x: 0, y: 0, width: 800, height: 600), standard: true)
    let small = window(2, CGRect(x: 100, y: 100, width: 200, height: 200), standard: true)  // vera finestra, solo piccola
    #expect(systemWindows([small, main]).map(\.id) == [2, 1])
}

// QA di MGS-615 (MGS-628): ingrandita dietro, Finder piccola davanti ({300, 300, 1000, 800} in CoreGraphics).
// Il fiocco sopra la finestra davanti deve arrivare al suo bordo, non fermarsi sul bordo in cima di quella dietro.
@Test func maximizedWindowBehindLeavesTheSnowToTheWindowInFront() {
    let maximized = (id: CGWindowID(1), rect: CGRect(x: 0, y: 0, width: 1920, height: 1050))
    let finder = (id: CGWindowID(2), rect: CGRect(x: 300, y: 1080 - 800 - 300, width: 1000, height: 800))
    let edges = visibleTopEdges([finder, maximized], clearance: 16)
    #expect(edges[0].visible == [300...1300])
    #expect(edges[1].visible == [0...300, 1300...1920])
}
