import UIKit
import os

/// A made-up library for previews, UI tests and App Store screenshots: about a hundred items
/// with duplicates, a burst, similar videos, blurry shots, chat photos, screenshots, videos and
/// Live Photos.
///
/// Photos are real pictures from `DemoPhotos` (Unsplash, credits in
/// `Fixtures/demo-photos-credits.md`), left out of Release builds: there, and for screens, the
/// pictures are drawn in code.
nonisolated final class DemoLibrary: PhotoLibrary {
    private struct Entry: Sendable {
        var item: MediaItem
        /// The picture in `DemoPhotos`, such as `demo-64`.
        var photo: String?
        /// Draws the landscape with this seed when the photo is missing, or a screen when `isScreen`.
        var seed: Int
        /// Moves the picture sideways, as in a burst or a retake.
        var shift: CGFloat = 0
        var isBlurred = false
        var isScreen = false
    }

    private struct Contents: Sendable {
        var access: LibraryAccess
        var entries: [Entry]
    }

    private static let pictureSize = CGSize(width: 1000, height: 750)
    private static let screenSize = CGSize(width: 590, height: 1278)

    private let contents: OSAllocatedUnfairLock<Contents>

    /// Creates the demo library.
    /// - Parameters:
    ///   - access: The access it pretends the user gave; requesting it gives full access.
    ///   - now: The day the library ends on.
    init(access: LibraryAccess = .full, now: Date = .now) {
        contents = OSAllocatedUnfairLock(initialState: Contents(access: access, entries: Self.makeEntries(now: now)))
    }

    func currentAccess() -> LibraryAccess {
        contents.withLock { $0.access }
    }

    func requestAccess() async -> LibraryAccess {
        contents.withLock { contents in
            if contents.access == .notDetermined {
                contents.access = .full
            }
            return contents.access
        }
    }

    func fetchItems() async -> [MediaItem] {
        contents.withLock { $0.entries.map { entry in
            var item = entry.item
            item.size = nil
            return item
        } }
    }

    func measure(_ ids: [String]) async -> [String: ItemSize] {
        let wanted = Set(ids)
        return contents.withLock { contents in
            Dictionary(uniqueKeysWithValues: contents.entries.filter { wanted.contains($0.item.id) }.compactMap { entry in
                entry.item.size.map { (entry.item.id, $0) }
            })
        }
    }

    func albums() async -> [Album] {
        [Album(id: "demo-album", title: String(localized: "Vacanze"), count: 6), Album(id: "demo-whatsapp", title: "WhatsApp", count: 4)]
    }

    func chatItemIDs() async -> Set<String> {
        contents.withLock { Set($0.entries.map(\.item.id).filter { $0.hasPrefix("chat") }) }
    }

    func itemIDs(inAlbum albumID: String) async -> [String] {
        let prefix = albumID == "demo-whatsapp" ? "chat" : "photo"
        return contents.withLock { Array($0.entries.map(\.item.id).filter { $0.hasPrefix(prefix) }.prefix(6)) }
    }

    @concurrent
    func image(for id: String, pixelSide: CGFloat) async -> UIImage? {
        guard let entry = entry(id) else { return nil }

        return Self.draw(entry)
    }

    func analyze(_ id: String) async -> ImageAnalysis? {
        guard let entry = entry(id), !entry.item.isScreenRecording else { return nil }

        return await Self.analyze(entry)
    }

    func videoURL(for id: String) async -> URL? {
        nil
    }

    func downloadVideo(for id: String, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        // The demo has no video files: it pretends a download, then says the video is unavailable.
        for step in 1...10 {
            try await Task.sleep(for: .milliseconds(150))
            progress(Double(step) / 10)
        }
        throw LibraryError.unavailable
    }

    func details(for id: String) async -> MediaDetails {
        guard let entry = entry(id) else { return MediaDetails() }

        return entry.isScreen
            ? MediaDetails(fileName: "IMG_\(1000 + entry.seed).PNG")
            : MediaDetails(fileName: "IMG_\(1000 + entry.seed).HEIC", camera: "iPhone", lens: nil)
    }

    func delete(_ ids: [String]) async throws {
        let gone = Set(ids)
        contents.withLock { $0.entries.removeAll { gone.contains($0.item.id) } }
    }

    func saveStill(ofLivePhoto id: String) async throws -> String {
        guard var entry = entry(id) else { throw LibraryError.unavailable }

        entry.item = MediaItem(id: "still-\(id)", creationDate: entry.item.creationDate, kind: .photo, isFavorite: entry.item.isFavorite,
                               pixelWidth: entry.item.pixelWidth, pixelHeight: entry.item.pixelHeight,
                               size: ItemSize(bytes: entry.item.bytes - (entry.item.size?.pairedVideoBytes ?? 0)))
        let still = entry
        contents.withLock { $0.entries.append(still) }
        return still.item.id
    }

    func saveCompressed(video id: String, quality: CompressionQuality, progress: @escaping @Sendable (CompressionStep) -> Void) async throws -> String {
        for step in 1...10 {
            try await Task.sleep(for: .milliseconds(100))
            progress(.compressing(Double(step) / 10))
        }
        guard var entry = entry(id) else { throw LibraryError.unavailable }

        let bytes = quality.estimatedBytes(duration: entry.item.duration, originalBytes: entry.item.bytes)
        entry.item = MediaItem(id: "compressed-\(id)", creationDate: entry.item.creationDate, kind: .video,
                               pixelWidth: 1280, pixelHeight: 720, duration: entry.item.duration, size: ItemSize(bytes: bytes))
        let compressed = entry
        contents.withLock { $0.entries.append(compressed) }
        return compressed.item.id
    }

    func changes() -> AsyncStream<Void> {
        AsyncStream { _ in }
    }

    private func entry(_ id: String) -> Entry? {
        contents.withLock { $0.entries.first { $0.item.id == id } }
    }

    @concurrent
    private static func analyze(_ entry: Entry) async -> ImageAnalysis? {
        guard let image = draw(entry).cgImage else { return nil }

        return ImageAnalyzer.analyze(image)
    }

    private static func draw(_ entry: Entry) -> UIImage {
        if entry.isScreen {
            return DemoPicture.screen(seed: entry.seed, size: screenSize)
        }
        if let name = entry.photo, let photo = DemoPicture.photo(named: name, shift: entry.shift, blurred: entry.isBlurred, size: pictureSize) {
            return photo
        }
        return DemoPicture.landscape(seed: entry.seed, shift: entry.shift, size: pictureSize)
    }

    // MARK: - Contents

    private static func makeEntries(now: Date) -> [Entry] {
        let day: TimeInterval = 86_400
        let minute: TimeInterval = 60
        var entries: [Entry] = []

        func photo(_ id: String, _ picture: Int, ago: TimeInterval, shift: CGFloat = 0, megabytes: Double = 3.2, live: Bool = false,
                   favorite: Bool = false, blurred: Bool = false) {
            let paired: Int64 = live ? 2_400_000 : 0
            let bytes = Int64(megabytes * 1_000_000) + paired
            let item = MediaItem(id: id, creationDate: now.addingTimeInterval(-ago), kind: .photo, isLivePhoto: live, isFavorite: favorite,
                                 pixelWidth: 4032, pixelHeight: 3024, size: ItemSize(bytes: bytes, pairedVideoBytes: paired))
            entries.append(Entry(item: item, photo: "demo-\(picture)", seed: picture, shift: shift, isBlurred: blurred))
        }

        func video(_ id: String, _ picture: Int, ago: TimeInterval, seconds: Double, megabytes: Double, shift: CGFloat = 0) {
            let item = MediaItem(id: id, creationDate: now.addingTimeInterval(-ago), kind: .video, pixelWidth: 3840, pixelHeight: 2160,
                                 duration: seconds, size: ItemSize(bytes: Int64(megabytes * 1_000_000)))
            entries.append(Entry(item: item, photo: "demo-\(picture)", seed: picture, shift: shift))
        }

        // The newest: a long concert video, then a burst at sunset.
        video("video-concert", 158, ago: day * 0.6, seconds: 252, megabytes: 1_140)
        for shot in 0..<3 {
            photo("burst-\(shot)", 65, ago: day * 1 + Double(shot) * 2, shift: CGFloat(shot) * 6, megabytes: 3.6 + Double(shot) * 0.1)
        }

        // Everyday photos of the last weeks, two Live Photos.
        for (index, picture) in [64, 75, 76, 102, 152, 163, 129, 146, 177, 116, 57, 22].enumerated() {
            photo("photo-\(index)", picture, ago: day * Double(index * 2 + 3), megabytes: 2.4 + Double(index % 4) * 0.6, favorite: index == 0)
        }
        photo("live-0", 40, ago: day * 4, live: true)
        photo("live-1", 169, ago: day * 12, live: true)

        // Shots out of focus or shaken.
        photo("blurry-0", 142, ago: day * 9, megabytes: 2.1, blurred: true)
        photo("blurry-1", 193, ago: day * 16, megabytes: 1.9, blurred: true)

        // Saved from WhatsApp.
        for (index, picture) in [200, 133, 183, 195].enumerated() {
            photo("chat-\(index)", picture, ago: day * Double(index * 4 + 2) + 3_600, megabytes: 0.3 + Double(index) * 0.08)
        }

        // Screenshots.
        for index in 0..<12 {
            let item = MediaItem(id: "screenshot-\(index)", creationDate: now.addingTimeInterval(-day * Double(index * 3 + 1) - 7_200), kind: .photo,
                                 isScreenshot: true, pixelWidth: 1179, pixelHeight: 2556, size: ItemSize(bytes: Int64(1_200_000 + index * 110_000)))
            entries.append(Entry(item: item, seed: 80 + index, isScreen: true))
        }

        // Videos: two retakes of the same view, and two screen recordings.
        video("video-beach", 199, ago: day * 6, seconds: 95, megabytes: 420)
        video("video-balloon", 174, ago: day * 26, seconds: 48, megabytes: 140)
        video("video-city-0", 43, ago: day * 40, seconds: 61, megabytes: 380)
        video("video-city-1", 43, ago: day * 40 + minute * 3, seconds: 52, megabytes: 310)
        for (index, (ago, megabytes)) in [(9.0, 640.0), (23.0, 210.0)].enumerated() {
            let recording = MediaItem(id: "recording-\(index)", creationDate: now.addingTimeInterval(-day * ago), kind: .video, isScreenRecording: true,
                                      pixelWidth: 1178, pixelHeight: 2556, duration: megabytes / 4, size: ItemSize(bytes: Int64(megabytes * 1_000_000)))
            entries.append(Entry(item: recording, seed: 95 + index, isScreen: true))
        }

        // Duplicates: one picture saved twice, another three times, far apart.
        photo("duplicate-a0", 49, ago: day * 15 + 600)
        photo("duplicate-a1", 49, ago: day * 75)
        photo("duplicate-b0", 164, ago: day * 33, megabytes: 4.1)
        photo("duplicate-b1", 164, ago: day * 120, megabytes: 4.1)
        photo("duplicate-b2", 164, ago: day * 200, megabytes: 4.1)

        // Accadde oggi: this day one and two years ago.
        for (years, pictures) in [(1, [186, 196]), (2, [197])] {
            let date = Calendar.current.date(byAdding: .year, value: -years, to: now) ?? now
            for (index, picture) in pictures.enumerated() {
                photo("photo-year-\(years)-\(index)", picture, ago: now.timeIntervalSince(date) + Double(index) * 3_600, megabytes: 2.9)
            }
        }

        // Older months, two photos each.
        let older = [10, 13, 17, 28, 37, 42, 54, 58, 62, 70, 85, 92, 99, 107, 110, 112, 118, 124, 128, 136, 154, 162, 165, 176, 179, 182]
        for month in 1..<14 {
            photo("old-\(month)-a", older[(month - 1) * 2], ago: day * Double(month * 30 + 3))
            photo("old-\(month)-b", older[(month - 1) * 2 + 1], ago: day * Double(month * 30 + 11), megabytes: 2.8)
        }

        return entries.sorted { ($0.item.creationDate ?? .distantPast) > ($1.item.creationDate ?? .distantPast) }
    }
}
