import SbuKit
import SwiftUI

/// The next maneuver, the limit, the voice, and the way back to following the route.
struct GuidanceTopView: View {
    let guidance: GuidanceModel
    @Bindable var model: MapModel

    var body: some View {
        VStack(alignment: .leading, spacing: SbuTheme.space2) {
            if let step = guidance.currentStep {
                HStack(alignment: .top, spacing: SbuTheme.space3) {
                    Image(systemName: step.maneuver.symbol)
                        .font(SbuTheme.largeTitle.weight(.medium))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.street ?? ManeuverText.action(step))
                            .font(SbuTheme.title2)
                            .lineLimit(2)
                        Text(Measurement(value: guidance.state.metresToManeuver, unit: UnitLength.meters), format: .measurement(width: .abbreviated, usage: .road))
                            .font(SbuTheme.headline)
                            .foregroundStyle(SbuTheme.inkMuted)
                    }
                    Spacer(minLength: 0)
                }
                .foregroundStyle(SbuTheme.ink)
                .padding(SbuTheme.space3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SbuTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: SbuTheme.radiusCard))
                .overlay(RoundedRectangle(cornerRadius: SbuTheme.radiusCard).strokeBorder(SbuTheme.line))
                .accessibilityElement(children: .combine)
            }
            HStack(alignment: .top) {
                if guidance.state.limit > 0 {
                    SpeedLimitBadge(kph: guidance.state.limit)
                }
                Spacer()
                IconButton(title: guidance.speaks ? "Disattiva la voce" : "Attiva la voce", symbol: guidance.speaks ? "speaker.wave.2" : "speaker.slash", isPill: true) {
                    guidance.speaks.toggle()
                    model.store.state.speaks = guidance.speaks
                }
            }
        }
        .padding(.horizontal, SbuTheme.space4)
    }
}
