import CoreGraphics
import Foundation
import Testing
@testable import SbuSeasons

/// Il secondo giro di vestiti per il pupazzo e l'angelo in cima all'albero (SBU-187).
@MainActor
struct WardrobeTests {
    @Test(arguments: SnowmanLook.Hat.allCases.filter { $0 != .none })
    func everyHatMakesItTaller(_ hat: SnowmanLook.Hat) {
        var look = SnowmanLook()
        look.hat = hat
        #expect(look.size.height > SnowmanLook().size.height)
    }

    @Test func theNewHatsAreThere() {
        let hats = Set(SnowmanLook.Hat.allCases)
        #expect(hats.isSuperset(of: [.cowboy, .party, .elf, .pirate, .crown, .antlers]))
    }

    @Test func mittensNeedRoomOnTheSides() {
        var look = SnowmanLook()
        look.mittens = true
        #expect(look.size.width > SnowmanLook().size.width)
    }

    @Test func aSnowmanSavedBeforeTheNewClothesStillOpens() throws {
        // Com'era salvato con la prima versione (SBU-178): senza occhi, muffole, papillon, maglione, mantello.
        let old = #"{"balls":["large","medium","small"],"hat":"beanie","scarf":"red","nose":"coal","buttons":false}"#
        let look = try JSONDecoder().decode(SnowmanLook.self, from: Data(old.utf8))
        #expect(look.balls == [.large, .medium, .small])
        #expect(look.hat == .beanie && look.scarf == .red && look.nose == .coal && !look.buttons)
        #expect(look.eyes == .coal && !look.mittens && !look.bowTie && !look.sweater && !look.cape)
    }

    @Test func theWholeWardrobeSurvivesTheTripToJSON() throws {
        var look = SnowmanLook()
        look.hat = .antlers
        look.eyes = .stars
        look.scarf = .striped
        look.mittens = true
        look.bowTie = true
        look.sweater = true
        look.cape = true
        #expect(try JSONDecoder().decode(SnowmanLook.self, from: JSONEncoder().encode(look)) == look)
    }

    @Test func dressingInEveryHatDrawsIt() {
        let snowman = Snowman(at: .zero)
        for hat in SnowmanLook.Hat.allCases {
            snowman.look.hat = hat
            #expect(snowman.node.size == snowman.look.size)
        }
    }

    // MARK: - Angelo

    @Test func theAngelGoesOnTopInsteadOfTheStar() {
        var look = TreeLook()
        look.hanging = .star
        look.hang(at: CGPoint(x: 0, y: 40))
        look.hanging = .angel
        look.hang(at: CGPoint(x: 5, y: 30))
        #expect(look.decorations.map(\.kind) == [.angel])
        #expect(look.decorations.first?.position == TreeLook.tip)
        look.hanging = .star
        look.hang(at: CGPoint(x: 0, y: 40))
        #expect(look.decorations.map(\.kind) == [.star], "in cima ce n'è uno solo")
    }

    @Test func theAngelStaysWhenDroppedNearTheTip() {
        var look = TreeLook()
        look.hanging = .angel
        look.hang(at: CGPoint(x: 0, y: 40))
        look.drop(0, at: CGPoint(x: 3, y: 79))
        #expect(look.decorations.count == 1)
    }
}
