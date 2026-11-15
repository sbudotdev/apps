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
