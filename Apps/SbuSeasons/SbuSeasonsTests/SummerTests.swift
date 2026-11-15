import CoreGraphics
import Testing
@testable import SbuSeasons

/// L'estate (MGS-431): semi di tarassaco, scelti da Matteo fra tre prototipi.
struct SummerTests {
    @Test func summerComesAfterSnowInTheSeasonMenu() {
        #expect(Seasons.all.map(\.id) == ["snow", "summer"])
        #expect(Seasons.named("summer") is Summer)
    }

    @Test(arguments: [0.0, 0.5, 1.0])
    func seedsFallSlowerAndSwayWiderThanSnow(depth: CGFloat) {
        let seed = Summer().particle(depth: depth), flake = Snow().particle(depth: depth)
        #expect(seed.fallSpeed < flake.fallSpeed)
        #expect(seed.swayAmplitude >= SummerTuning.sway.lowerBound)
        #expect(SummerTuning.sway.lowerBound > 8)   // la neve ondeggia fra 8 e 26 pt
    }
}
