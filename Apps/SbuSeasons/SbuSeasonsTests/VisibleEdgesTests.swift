import Testing
import CoreGraphics
@testable import SbuSeasons

@Test func frontWindowHidesPartOfTheEdgeBehind() {
    let back = (id: CGWindowID(1), rect: CGRect(x: 0, y: 0, width: 400, height: 300))       // bordo a y=300
    let front = (id: CGWindowID(2), rect: CGRect(x: 100, y: 200, width: 100, height: 200))  // copre x 100…200
    let away = (id: CGWindowID(3), rect: CGRect(x: 250, y: 0, width: 50, height: 100))      // troppo in basso

    let edges = visibleTopEdges([front, away, back], clearance: 16)

    #expect(edges[0].visible == [100...200])           // la finestra davanti è libera
    #expect(edges[2].visible == [0...100, 200...400])  // dietro: buco dove c'è quella davanti
    #expect(edges[1].visible == [250...300])           // "away" non copre il bordo di "back" (è sotto)
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
