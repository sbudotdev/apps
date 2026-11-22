import Observation
import UIKit

/// The pictures of the cards around the top one, loaded and decoded ahead, off the main actor.
///
/// Each new card used to load its photo when it reached the top, and to decode it on the main
/// actor when drawn: the card showed empty for a moment, then the photo popped in. Now the next
/// cards are ready before the swipe, and the previous one stays for undo.
@Observable
final class CardImages {
    /// The width of a card at full resolution on the largest iPhone, in pixels.
    static let pixelSide: CGFloat = 1_320

    private(set) var images: [String: UIImage] = [:]

    func image(for id: String) -> UIImage? {
        images[id]
    }

    /// Keeps the pictures of `ids`, loads the missing ones, and lets the others go.
    func keep(_ ids: [String], from library: any PhotoLibrary) async {
        let wanted = Set(ids)
        images = images.filter { wanted.contains($0.key) }
        let missing = ids.filter { images[$0] == nil }
        await withTaskGroup(of: (String, UIImage?).self) { group in
            for id in missing {
                group.addTask { (id, await Self.load(id, from: library)) }
            }
            for await (id, image) in group {
                if let image, !Task.isCancelled {
                    images[id] = image
                }
            }
        }
    }

    /// Loads the picture and decodes it, so drawing it costs nothing on the main actor.
    @concurrent
    private nonisolated static func load(_ id: String, from library: any PhotoLibrary) async -> UIImage? {
        let image = await library.image(for: id, pixelSide: pixelSide)
        return await image?.byPreparingForDisplay() ?? image
    }
}
