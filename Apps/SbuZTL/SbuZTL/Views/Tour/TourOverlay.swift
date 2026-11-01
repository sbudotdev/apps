import SbuKit
import SwiftUI

/// The first look at the map: where to search, which moment, which vehicle.
struct TourOverlay: View {
    let anchors: [TourAnchor: Anchor<CGRect>]
    let onFinish: () -> Void
    @State private var index = 0

    private let steps: [(anchor: TourAnchor, text: LocalizedStringKey)] = [
        (.search, "Cerca dove vai. Ti dico se ci puoi entrare."),
        (.vehicle, "La risposta dipende dal tuo veicolo."),
        (.moment, "E da quando guidi: scegli un altro giorno o un'altra ora."),
    ]

    var body: some View {
        GeometryReader { proxy in
            let hole = anchors[steps[index].anchor].map { proxy[$0].insetBy(dx: -4, dy: -4) }
            ZStack {
                Rectangle()
                    .fill(SbuTheme.ink.opacity(0.55))
                    .overlay {
                        if let hole {
                            RoundedRectangle(cornerRadius: SbuTheme.radiusCard)
                                .frame(width: hole.width, height: hole.height)
                                .position(x: hole.midX, y: hole.midY)
                                .blendMode(.destinationOut)
                        }
                    }
                    .compositingGroup()
                    .ignoresSafeArea()
                VStack(alignment: .leading, spacing: SbuTheme.space3) {
                    Text(steps[index].text)
                        .font(SbuTheme.headline)
                        .foregroundStyle(SbuTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    SbuButton(index == steps.count - 1 ? "Inizia" : "Avanti", action: advance)
                        .accessibilityIdentifier("tourNext")
                }
                .padding(SbuTheme.space4)
                .background(SbuTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: SbuTheme.radiusLg))
                .padding(SbuTheme.space4)
                .frame(maxHeight: .infinity, alignment: (hole?.midY ?? 0) > proxy.size.height / 2 ? .top : .bottom)
            }
        }
        .accessibilityAddTraits(.isModal)
    }

    private func advance() {
        if index == steps.count - 1 {
            onFinish()
        } else {
            index += 1
        }
    }
}
