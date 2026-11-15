import CoreGraphics
import Testing
@testable import SbuSeasons

/// L'autunno (MGS-429): foglie che ondeggiano, girano su se stesse e si posano in mucchi radi.
struct AutumnTests {
    @Test func autumnIsInTheSeasonMenu() {
        #expect(Seasons.all.contains { $0.id == "autumn" })
        #expect(Seasons.named("autumn") is Autumn)
    }

    @Test(arguments: [0.0, 0.5, 1.0])
    func leavesTumbleAndTakeAnAutumnColor(depth: CGFloat) {
        let leaf = Autumn().particle(depth: depth)
        #expect(leaf.spin != 0)
        #expect(leaf.flip > 0)
        #expect(AutumnTuning.leaves.contains { $0 == leaf.tint })
        #expect(leaf.fallSpeed < Snow().particle(depth: depth).fallSpeed)
    }

    @Test func leavesPileUpSparserThanSnow() {
        let growth = Autumn().pileGrowth
        #expect((growth.lowerBound + growth.upperBound) / 2 < 1)
        #expect(growth.upperBound - growth.lowerBound > 0.5)   // irregolari: ogni foglia aggiunge quanto vuole
    }
}
