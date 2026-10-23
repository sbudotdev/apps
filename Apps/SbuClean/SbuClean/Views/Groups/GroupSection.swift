import SbuKit
import SwiftUI

/// One group: its size, a button for all the copies, and the photos in a row, best first.
struct GroupSection: View {
    let model: CleanModel
    let group: PhotoGroup

    @ScaledMetric(relativeTo: .body) private var tileSide: CGFloat = 120
    @State private var playing: MediaItem?

    private var isVideo: Bool {
        group.kind == .videos
    }

    var body: some View {
        VStack(alignment: .leading, spacing: SbuTheme.space2) {
            HStack(alignment: .firstTextBaseline) {
                Text(isVideo
                     ? "\(group.members.count) video · \(model.bytes(of: group.members).sizeText)"
                     : "\(group.members.count) foto · \(model.bytes(of: group.members).sizeText)")
                    .font(SbuTheme.subheadline)
                    .foregroundStyle(SbuTheme.inkMuted)
                Spacer(minLength: SbuTheme.space2)
                Button(toggleTitle, action: toggleAll)
                    .font(SbuTheme.subheadline)
                    .frame(minHeight: 44)
                    .contentShape(.rect)
            }

            ScrollView(.horizontal) {
                HStack(spacing: SbuTheme.space2) {
                    ForEach(Array(group.members.enumerated()), id: \.element) { index, id in
                        GroupTile(
                            id: id,
                            position: index + 1,
                            count: group.members.count,
                            isBest: id == group.best,
                            isSelected: model.groupSelection.isSelected(id, in: group),
                            isVideo: isVideo,
                            play: { playing = model.itemsByID[id] }
                        ) {
                            model.groupSelection.toggle(id, in: group)
                        }
                        .frame(width: tileSide, height: tileSide)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .sheet(item: $playing) { video in
            VideoPreviewSheet(item: video)
        }
    }

    private var toggleTitle: LocalizedStringKey {
        let allSelected = model.groupSelection.areAllCopiesSelected(in: group)
        return switch (isVideo, allSelected) {
        case (true, true): "Tieni tutti"
        case (true, false): "Tieni solo il migliore"
        case (false, true): "Tieni tutte"
        case (false, false): "Tieni solo la migliore"
        }
    }

    private func toggleAll() {
        model.groupSelection.toggleAllCopies(in: group)
    }
}

#Preview("Light") {
    GroupSection(model: .preview, group: PhotoGroup(kind: .duplicate, members: ["duplicate-b0", "duplicate-b1", "duplicate-b2"]))
        .padding()
        .environment(\.sbuAccent, .clean)
}

#Preview("Dark") {
    GroupSection(model: .preview, group: PhotoGroup(kind: .similar, members: ["burst-0", "burst-1"]))
        .padding()
        .environment(\.sbuAccent, .clean)
        .preferredColorScheme(.dark)
}
