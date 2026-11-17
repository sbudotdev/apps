import Foundation
import Testing
@testable import SbuSeasons

/// Il corpo di un oggetto: cade, si posa sui bordi scoperti, si tiene in mano e si lancia.
struct ToyBodyTests {
    private let floor = Ledge(y: 0, span: 0...1000)
    private let window = Ledge(y: 300, span: 100...400)

    /// Fa andare il corpo per `seconds` a 60 fotogrammi al secondo.
    private func run(_ body: inout ToyBody, _ ledges: [Ledge], seconds: CGFloat = 2, bounce: CGFloat = 0) {
        for _ in 0..<Int(seconds * 60) { body.step(dt: 1.0 / 60, ledges: ledges, width: 1000, bounce: bounce) }
    }

    @Test func fallsAndRestsOnTheWindowEdgeBelow() {
        var body = ToyBody(position: CGPoint(x: 200, y: 600))
        run(&body, [floor, window])
        #expect(body.position.y == 300)
        #expect(body.isResting)
    }

    @Test func aCoveredStretchDoesNotHoldIt() {
        var body = ToyBody(position: CGPoint(x: 50, y: 600))   // fuori dal tratto scoperto
        run(&body, [floor, window])
        #expect(body.position.y == 0)
    }

    @Test func fallsWhenTheWindowGoesAway() {
        var body = ToyBody(position: CGPoint(x: 200, y: 600))
        run(&body, [floor, window])
        run(&body, [floor])
        #expect(body.position.y == 0)
        #expect(body.isResting)
    }

    @Test func aHeldBodyDoesNotFall() {
        var body = ToyBody(position: CGPoint(x: 200, y: 600))
        body.hold(at: CGPoint(x: 500, y: 700))
        run(&body, [floor])
        #expect(body.position == CGPoint(x: 500, y: 700))
    }

    @Test func aThrowCarriesItSidewaysAndItStaysOnScreen() {
        var body = ToyBody(position: CGPoint(x: 500, y: 100))
        body.hold(at: CGPoint(x: 500, y: 100))
        body.release(velocity: CGVector(dx: 3000, dy: 0))
        run(&body, [floor])
        #expect(body.position.x > 500)
        #expect(body.position.x <= 1000)
        #expect(body.position.y == 0)
    }

    @Test func itBouncesOnlyWithBounce() {
        var bouncy = ToyBody(position: CGPoint(x: 200, y: 600))
        var flat = bouncy
        // Il primo contatto col bordo arriva dopo circa 0,65 s: subito dopo, chi rimbalza è già in aria.
        run(&bouncy, [floor, window], seconds: 0.75, bounce: 0.5)
        run(&flat, [floor, window], seconds: 0.75, bounce: 0)
        #expect(bouncy.position.y > 300)
        #expect(flat.position.y == 300)
    }
}
