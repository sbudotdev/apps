import SbuKit
import SwiftUI

/// A large area to drive the prompter without looking: tap to start or pause, swipe up and down
/// for the speed, left and right for the cues. VoiceOver gets the same as named actions.
struct GesturePad: View {
    let isPlaying: Bool
    let perform: (PrompterCommand) -> Void

    @ScaledMetric(relativeTo: .body) private var minHeight: CGFloat = 180

    var body: some View {
        VStack(spacing: SbuTheme.space3) {
            Image(systemName: isPlaying ? "pause" : "play")
                .font(.largeTitle.weight(.medium))
                .foregroundStyle(SbuTheme.ink)
            Text("Tocca per avviare o fermare. Scorri su e giù per la velocità, a sinistra e a destra per le sezioni.")
                .font(SbuTheme.body)
                .foregroundStyle(SbuTheme.inkMuted)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(SbuTheme.space4)
        .frame(maxWidth: .infinity, minHeight: minHeight)
        .background(SbuTheme.surfaceRaised, in: .rect(cornerRadius: SbuTheme.radiusCard))
        .overlay(RoundedRectangle(cornerRadius: SbuTheme.radiusCard).strokeBorder(SbuTheme.line))
        .contentShape(.rect)
        .onTapGesture { perform(.togglePlay) }
        .gesture(DragGesture(minimumDistance: RemoteModel.swipeDistance).onEnded { drag in
            if let command = RemoteModel.command(forSwipe: drag.translation) { perform(command) }
        })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Area dei gesti"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { perform(.togglePlay) }
        .accessibilityAction(named: Text("Più veloce")) { perform(.faster) }
        .accessibilityAction(named: Text("Più lento")) { perform(.slower) }
        .accessibilityAction(named: Text("Sezione successiva")) { perform(.nextCue) }
        .accessibilityAction(named: Text("Sezione precedente")) { perform(.previousCue) }
    }
}

#Preview("Light") {
    GesturePad(isPlaying: false) { _ in }.padding()
}

#Preview("Dark") {
    GesturePad(isPlaying: true) { _ in }.padding()
        .preferredColorScheme(.dark)
}
