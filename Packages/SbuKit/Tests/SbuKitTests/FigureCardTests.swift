import Foundation
import Testing
import ImageIO
@testable import SbuKit

@MainActor
struct FigureCardTests {
    @Test(arguments: ["12", "544,34 €", "1.237,83 €"])
    func theCardIs1080By1350Pixels(value: String) throws {
        let card = SbuFigureCardImage(value: value, word: "all'anno", appName: "Sbu Subscriptions", accent: .subscriptions)
        let source = try #require(CGImageSourceCreateWithData(try card.pngData() as CFData, nil))
        let image = try #require(CGImageSourceCreateImageAtIndex(source, 0, nil))
        #expect(image.width == 1080)
        #expect(image.height == 1350)
    }

    @Test func theSignatureNamesTheAppAndTheSite() {
        #expect(SbuFigureCard.signature(appName: "Sbu Habits") == "SBU HABITS · SBU.DEV")
    }
}
