import SbuKit
import SwiftUI

/// The picture on a card: the whole photo, or the video ready to play.
struct SwipeCardContent: View {
    let item: MediaItem
    var playsVideo = false
    /// The picture loaded ahead by the deck; without it the card loads its own.
    var image: UIImage?

    /// Without a picture loaded ahead, the card's width in points (at the screen's scale).
    static let pictureSide: CGFloat = 440

    var body: some View {
        Group {
            if item.kind == .video && playsVideo {
                VideoCardPlayer(item: item, poster: image)
            } else if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityHidden(true)
            } else {
                MediaThumbnail(id: item.id, side: Self.pictureSide, contentMode: .fit)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SbuTheme.surfaceSunken)
        .clipShape(.rect(cornerRadius: SbuTheme.radiusCard))
    }
}

#Preview("Light") {
    SwipeCardContent(item: MediaItem(id: "photo-1", kind: .photo))
        .padding()
}

#Preview("Dark") {
    SwipeCardContent(item: MediaItem(id: "photo-1", kind: .photo))
        .padding()
        .preferredColorScheme(.dark)
}
