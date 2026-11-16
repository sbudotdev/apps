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
@Test(arguments: [
    (edgeTop: CGFloat(1000), expected: CGFloat?(1000)),  // c'è posto: la neve sta sul bordo
    (edgeTop: CGFloat(1050), expected: CGFloat?(1034)),  // attaccata alla barra (ingrandita): poco sotto
    (edgeTop: CGFloat(1040), expected: CGFloat?(1034)),  // il mucchio arriverebbe nella barra: poco sotto
    (edgeTop: CGFloat(1080), expected: nil),             // schermo intero: niente neve
])
func snowSitsJustBelowTheMenuBar(edgeTop: CGFloat, expected: CGFloat?) {
    #expect(pileBase(edgeTop: edgeTop, pileHeight: 16, ceiling: 1050) == expected)
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
