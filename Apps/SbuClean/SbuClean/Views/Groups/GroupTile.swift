import SbuKit
import SwiftUI

/// A photo or video in a group: the best one carries "Migliore", a selected one the bin mark.
/// A video has a play button, to watch it before deciding.
struct GroupTile: View {
    let id: String
    let position: Int
    let count: Int
    let isBest: Bool
    let isSelected: Bool
    var isVideo = false
    var play: () -> Void = {}
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle) {
            MediaThumbnail(id: id)
                .overlay(alignment: .topTrailing) {
                    SelectionMark(isSelected: isSelected)
                }
                .overlay(alignment: .bottomLeading) {
                    if isBest {
                        BestBadge()
                    }
                }
                .clipShape(.rect(cornerRadius: SbuTheme.radiusMd))
        }
        .buttonStyle(.plain)
        .overlay {
            if isVideo {
                Button("Guarda", systemImage: "play.fill", action: play)
                    .labelStyle(.iconOnly)
                    .fontWeight(.medium)
                    .foregroundStyle(SbuTheme.paper)
                    .frame(width: 44, height: 44)
                    .background(SbuTheme.ink.opacity(0.6), in: .circle)
                    .accessibilityHidden(true)
            }
        }
        .sbuAffectsFigure(isSelected)
        .accessibilityLabel(label)
        .accessibilityValue(isSelected ? Text("Da eliminare") : Text("Da tenere"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityAction(named: Text("Guarda")) {
            if isVideo {
                play()
            }
        }
    }

    private var label: Text {
        switch (isVideo, isBest) {
        case (true, true): Text("Video \(position) di \(count), il migliore")
        case (true, false): Text("Video \(position) di \(count)")
        case (false, true): Text("Foto \(position) di \(count), la migliore")
        case (false, false): Text("Foto \(position) di \(count)")
        }
    }
}

#Preview("Light") {
    GroupTile(id: "burst-0", position: 1, count: 3, isBest: true, isSelected: false) {}
        .frame(width: 120, height: 120)
        .environment(\.sbuAccent, .clean)
}

#Preview("Dark") {
    GroupTile(id: "burst-1", position: 2, count: 3, isBest: false, isSelected: true) {}
        .frame(width: 120, height: 120)
        .environment(\.sbuAccent, .clean)
        .preferredColorScheme(.dark)
}
