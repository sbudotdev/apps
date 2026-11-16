import SpriteKit
import Testing
@testable import SbuSeasons

/// Ogni schermo disegna la sua scena con un `SKRenderer` (non un `SKView`), quindi
/// `didMove(to:)` non arriva mai: i fiocchi devono nascere appena la scena gira (MGS-636).
@MainActor
@Test func flakesAppearAsSoonAsTheSceneRunsWithoutAView() {
    let scene = SeasonScene(size: CGSize(width: 400, height: 300), screenOrigin: .zero, season: Snow())
    scene.update(1)
    scene.update(1.016)
    #expect(!scene.children.compactMap { $0 as? SKSpriteNode }.isEmpty)
}
