import SbuKit
import SwiftUI

/// The first look at the real map, on an example: where you go, the answer, your vehicle, your moment.
struct TourOverlay: View {
    let model: MapModel
    let anchors: [TourAnchor: Anchor<CGRect>]
    /// `true` when you reached the last step, `false` when you skipped.
    let onFinish: (Bool) -> Void
    @State private var index = 0

    private let steps: [(anchor: TourAnchor, text: LocalizedStringKey)] = [
        (.search, "Cerca dove vai."),
        (.answer, "Ti dico subito se puoi entrare. Qui vedi il Duomo di Milano."),
        (.vehicle, "La risposta dipende dal tuo veicolo."),
        (.moment, "E dall'ora: scegli un altro giorno o un altro orario."),
    ]

    private var isLast: Bool { index == steps.count - 1 }

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
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: SbuTheme.space3) {
                    Text(steps[index].text)
                        .font(SbuTheme.headline)
                        .foregroundStyle(SbuTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: SbuTheme.space2) { buttons }
                        VStack(spacing: SbuTheme.space2) { buttons }
                    }
                }
                .padding(SbuTheme.space4)
                .background(SbuTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: SbuTheme.radiusLg))
                .padding(SbuTheme.space4)
                .frame(maxHeight: .infinity, alignment: (hole?.midY ?? 0) > proxy.size.height / 2 ? .top : .bottom)
            }
        }
        .accessibilityAddTraits(.isModal)
    }

    @ViewBuilder
    private var buttons: some View {
        if !isLast {
            SbuButton("Salta", kind: .secondary) { end(completed: false) }
                .accessibilityIdentifier("tourSkip")
        }
        SbuButton(isLast ? "Inizia" : "Avanti", action: advance)
            .accessibilityIdentifier("tourNext")
    }

    private func advance() {
        guard !isLast else { return end(completed: true) }
        index += 1
        if steps[index].anchor == .answer { model.showExample() }
    }

    private func end(completed: Bool) {
        model.close()
        onFinish(completed)
    }
}
