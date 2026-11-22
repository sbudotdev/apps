import SbuKit
import SwiftUI

/// A card of the stack. On top: drag right to keep, left to put in the bin; while dragging the
/// word Tieni or Elimina appears, and a long press shows the details. Under it: smaller and
/// faded, out of reach. The same view moves from under to on top, so its picture stays.
struct SwipeCard: View {
    let item: MediaItem
    var isOnTop = true
    var image: UIImage?
    let decide: (SwipeDecision) -> Void
    let showDetails: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var offset = CGSize.zero

    /// How far a drag must go to count as a decision.
    private static let threshold: CGFloat = 110
    /// How far the word fades in.
    private static let labelDistance: CGFloat = 80

    var body: some View {
        SwipeCardContent(item: item, playsVideo: isOnTop, image: image)
            // Only while dragged: invisible words still reached the accessibility audit.
            .overlay(alignment: .topLeading) {
                if offset.width > 0 {
                    DecisionLabel(decision: .keep)
                        .opacity(min(1, offset.width / Self.labelDistance))
                }
            }
            .overlay(alignment: .topTrailing) {
                if offset.width < 0 {
                    DecisionLabel(decision: .trash)
                        .opacity(min(1, -offset.width / Self.labelDistance))
                }
            }
            .offset(x: offset.width, y: offset.height / 5)
            .rotationEffect(reduceMotion ? .zero : .degrees(offset.width / 25))
            .gesture(drag)
            .onLongPressGesture(minimumDuration: 0.5, perform: showDetails)
            .scaleEffect(isOnTop ? 1 : 0.94)
            .opacity(isOnTop ? 1 : 0.6)
            .allowsHitTesting(isOnTop)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(item.spokenDescription)
            .accessibilityHint("Scorri a destra per tenere, a sinistra per il cestino")
            .accessibilityAction(named: "Tieni") { decide(.keep) }
            .accessibilityAction(named: "Metti nel cestino") { decide(.trash) }
            .accessibilityAction(named: "Decidi dopo") { decide(.later) }
            .accessibilityAction(named: "Tieni sempre") { decide(.keepForever) }
            .accessibilityAction(named: "Dettagli", showDetails)
            .accessibilityIdentifier("swipe.card")
            // Last, so the card under the top one is out of VoiceOver's reach entirely.
            .accessibilityHidden(!isOnTop)
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 12)
            .onChanged { value in
                offset = value.translation
            }
            .onEnded { value in
                let distance = value.predictedEndTranslation.width
                if distance > Self.threshold {
                    decide(.keep)
                } else if distance < -Self.threshold {
                    decide(.trash)
                } else {
                    withAnimation(SbuMotion.animation(SbuMotion.spring, reduceMotion: reduceMotion)) {
                        offset = .zero
                    }
                }
            }
    }
}

#Preview("Light") {
    SwipeCard(item: MediaItem(id: "photo-2", kind: .photo), decide: { _ in }, showDetails: {})
        .padding()
        .environment(\.sbuAccent, .clean)
}

#Preview("Dark") {
    SwipeCard(item: MediaItem(id: "photo-2", kind: .photo), decide: { _ in }, showDetails: {})
        .padding()
        .environment(\.sbuAccent, .clean)
        .preferredColorScheme(.dark)
}
