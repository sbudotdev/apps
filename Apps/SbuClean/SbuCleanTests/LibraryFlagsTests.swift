import Foundation
import Testing
@testable import SbuClean

/// Chat photos and blurry photos: flagged on the library, counted on the home, kept out of the
/// space you can free.
struct LibraryFlagsTests {
    private let directory = Fixture.directory()

    @Test func chatAndBlurryPhotosAreFlaggedAndCounted() async {
        let items = [
            Fixture.photo("chat", on: Fixture.date(10, 1), bytes: 300_000),
            Fixture.photo("shaken", on: Fixture.date(9, 1), bytes: 2_000_000),
            Fixture.photo("sharp", on: Fixture.date(8, 1), bytes: 3_000_000),
        ]
        let analyses = [
            "chat": ImageAnalysis(featurePrint: Fixture.print(axis: 0), sharpness: 400, side: 512),
            "shaken": ImageAnalysis(featurePrint: Fixture.print(axis: 1), sharpness: 8, side: 512),
            "sharp": ImageAnalysis(featurePrint: Fixture.print(axis: 2), sharpness: 600, side: 512),
        ]
        let library = FakeLibrary(items: items, sizes: Dictionary(uniqueKeysWithValues: items.compactMap { item in item.size.map { (item.id, $0) } }), analyses: analyses)
        library.update { $0.chats = ["chat"] }
        let model = CleanModel(library: library, directory: directory, now: { Fixture.date(10, 13) }, readStorage: { nil })

        await model.reload()
        await model.waitForScan()
        await model.waitForSummary()

        #expect(model.items(in: .chats).map(\.id) == ["chat"])
        #expect(model.items(in: .blurry).map(\.id) == ["shaken"])
        #expect(model.summary.chats == LibrarySummary.Category(count: 1, bytes: 300_000))
        #expect(model.summary.blurry == LibrarySummary.Category(count: 1, bytes: 2_000_000))
        #expect(model.freeableBytes == 0)
    }

    @Test func aPhotoKeptForeverLeavesTheBlurryList() async {
        let items = [Fixture.photo("shaken", on: Fixture.date(9, 1))]
        let analyses = ["shaken": ImageAnalysis(featurePrint: Fixture.print(axis: 1), sharpness: 8, side: 512)]
        let library = FakeLibrary(items: items, sizes: ["shaken": ItemSize(bytes: 1_000_000)], analyses: analyses)
        let model = CleanModel(library: library, directory: directory, now: { Fixture.date(10, 13) }, readStorage: { nil })
        await model.reload()
        await model.waitForScan()

        model.decide(.keepForever, on: "shaken")

        #expect(model.items(in: .blurry).isEmpty)
    }
}
