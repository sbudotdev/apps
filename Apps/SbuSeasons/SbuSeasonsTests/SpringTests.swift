import CoreGraphics
import Testing
@testable import SbuSeasons

/// La primavera (MGS-430): petali leggeri, lenti, che svolazzano.
struct SpringTests {
    @Test func springIsInTheSeasonMenu() {
        #expect(Seasons.all.map(\.id).contains("spring"))
        #expect(Seasons.named("spring") is Spring)
    }

    /// Più lenti e più mossi della neve: a parità di vento e di cursore si spostano di più per ogni punto di caduta.
    @Test(arguments: [0.0, 0.5, 1.0])
    func petalsFallSlowerAndFlutterWiderThanSnow(depth: CGFloat) {
        let petal = Spring().particle(depth: depth), flake = Snow().particle(depth: depth)
        #expect(petal.fallSpeed < flake.fallSpeed)
        #expect(petal.swayAmplitude >= SpringTuning.flutter.lowerBound)
        #expect(SpringTuning.flutter.lowerBound > 26)   // la neve ondeggia fra 8 e 26 pt
    }
}

extension SpringTests {
    /// I petali non fanno mucchio: ognuno resta intero sulla finestra per un po' e poi sfuma (SBU-177).
    @Test func petalsRestOnTheWindowsForAWhile() throws {
        let linger = try #require(Spring().linger)
        #expect(linger.lowerBound >= 10)
        #expect(linger.upperBound <= 60)
    }

    /// I petali girano e si ribaltano piano mentre cadono, non tutti uguali.
    @Test func petalsTumbleWhileFalling() {
        let petals = (0..<20).map { _ in Spring().particle(depth: 0.5) }
        #expect(petals.allSatisfy { $0.spin != 0 && $0.flip > 0 })
        #expect(Set(petals.map(\.spin)).count > 1)
    }
}
