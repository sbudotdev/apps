import Foundation
import Testing
@testable import SbuClean

struct BlurCheckTests {
    struct Case: CustomTestStringConvertible, Sendable {
        var name: String
        var item: MediaItem
        var analysis: ImageAnalysis?
        var isBlurry: Bool

        var testDescription: String { name }
    }

    nonisolated static let cases = [
        Case(name: "low score", item: Fixture.photo("a"), analysis: ImageAnalysis(featurePrint: [], sharpness: 12, side: 512), isBlurry: true),
        Case(name: "sharp", item: Fixture.photo("a"), analysis: ImageAnalysis(featurePrint: [], sharpness: 140, side: 512), isBlurry: false),
        Case(name: "small copy", item: Fixture.photo("a"), analysis: ImageAnalysis(featurePrint: [], sharpness: 12, side: 120), isBlurry: false),
        Case(name: "saved before 1.1", item: Fixture.photo("a"), analysis: ImageAnalysis(featurePrint: [], sharpness: 12), isBlurry: false),
        Case(name: "screenshot", item: Fixture.photo("a", screenshot: true), analysis: ImageAnalysis(featurePrint: [], sharpness: 2, side: 512), isBlurry: false),
        Case(name: "favourite", item: Fixture.photo("a", favorite: true), analysis: ImageAnalysis(featurePrint: [], sharpness: 2, side: 512), isBlurry: false),
        Case(name: "video", item: Fixture.video("a"), analysis: ImageAnalysis(featurePrint: [], sharpness: 2, side: 512), isBlurry: false),
        Case(name: "not analysed", item: Fixture.photo("a"), analysis: nil, isBlurry: false),
    ]

    @Test(arguments: cases)
    func blurry(_ test: Case) {
        #expect(BlurCheck.isBlurry(test.item, analysis: test.analysis) == test.isBlurry)
    }

    @Test func aBlurredPictureScoresUnderTheThreshold() throws {
        // A sharp edge and the same edge smeared over many pixels, as the analyzer measures them.
        let side = 300
        var sharp = [UInt8](repeating: 0, count: side * side)
        var smeared = sharp
        for y in 0..<side {
            for x in 0..<side {
                sharp[y * side + x] = (x / 10 + y / 10).isMultiple(of: 2) ? 230 : 20
                smeared[y * side + x] = UInt8(125 + 100 * sin(Double(x) / 40))
            }
        }

        #expect(Sharpness.laplacianVariance(of: sharp, width: side, height: side) > BlurCheck.threshold)
        #expect(Sharpness.laplacianVariance(of: smeared, width: side, height: side) < BlurCheck.threshold)
    }

    @Test func anAnalysisWithoutSideStillDecodes() throws {
        let old = #"{"featurePrint":"AACAPw==","sharpness":12}"#
        let analysis = try JSONDecoder().decode(ImageAnalysis.self, from: Data(old.utf8))

        #expect(analysis.side == 0)
        #expect(analysis.featurePrint == [1])
    }
}
