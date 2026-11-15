import AppKit
import CoreGraphics
import Testing
@testable import SbuSeasons

/// L'estate (MGS-431): semi di tarassaco, scelti da Matteo fra tre prototipi.
struct SummerTests {
    @Test func summerIsInTheSeasonMenu() {
        #expect(Seasons.all.map(\.id).contains("summer"))
        #expect(Seasons.named("summer") is Summer)
    }

    @Test(arguments: [0.0, 0.5, 1.0])
    func seedsFallSlowerAndSwayWiderThanSnow(depth: CGFloat) {
        let seed = Summer().particle(depth: depth), flake = Snow().particle(depth: depth)
        #expect(seed.fallSpeed < flake.fallSpeed)
        #expect(seed.swayAmplitude >= SummerTuning.sway.lowerBound)
        #expect(SummerTuning.sway.lowerBound > 8)   // la neve ondeggia fra 8 e 26 pt
    }

    /// QA MGS-448: su una finestra bianca il ventaglio bianco spariva. Sopra il chicco
    /// (metà alta della texture) devono esserci pixel che si staccano dal bianco.
    @Test func theFluffStaysVisibleOnAWhiteWindow() {
        let image = Summer().makeTexture().cgImage()
        let rep = NSBitmapImageRep(cgImage: image)
        var visible = 0
        for x in 0..<rep.pixelsWide {
            for y in 0..<(rep.pixelsHigh / 2) {   // y = 0 è la riga in alto
                guard let c = rep.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { continue }
                // Composto su bianco: quanto si scosta dal bianco.
                let onWhite = 1 - c.alphaComponent * (1 - min(c.redComponent, c.greenComponent, c.blueComponent))
                if onWhite < 0.85 { visible += 1 }
            }
        }
        #expect(visible > 20)
    }
}
