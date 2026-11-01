import SbuKit
import SwiftUI

/// The tool screen: the map, with one panel for each step of the flow.
struct MapScreen: View {
    @Bindable var model: MapModel
    @Binding var isTourRunning: Bool

    private var route: RoutePlan? {
        switch model.phase {
        case .preview(_, let plan): plan
        case .guiding(_, let guidance): guidance.plan
        default: nil
        }
    }

    private var marker: Place? {
        switch model.phase {
        case .place(let place), .planning(let place), .preview(let place, _), .guiding(let place, _): place
        default: nil
        }
    }

    var body: some View {
        ZStack {
            ZoneMapView(model: model, route: route, marker: marker)
                .overlay(alignment: .bottomTrailing) {
                    if case .home = model.phase {
                        MapLocationButton(model: model).padding(SbuTheme.space4)
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) { panel }
                .overlay(alignment: .top) { top }
                .overlay { planningDialog }
            if case .search = model.phase {
                SearchScreen(model: model)
                    .transition(.opacity)
            }
        }
        .animation(SbuMotion.short, value: phaseKey)
        .overlay(alignment: .top) { problemBanner }
    }

    /// For the animation: which step, not its contents.
    private var phaseKey: Int {
        switch model.phase {
        case .home: 0
        case .search: 1
        case .place: 2
        case .planning: 3
        case .preview: 4
        case .guiding: 5
        }
    }

    @ViewBuilder
    private var top: some View {
        switch model.phase {
        case .guiding(_, let guidance):
            GuidanceTopView(guidance: guidance, model: model)
        case .preview(let place, _):
            RouteHeader(place: place)
        default:
            VStack(alignment: .trailing, spacing: SbuTheme.space2) {
                MapTopBar(model: model)
                MapSideButtons(model: model)
            }
            .padding(.horizontal, SbuTheme.space4)
        }
    }

    @ViewBuilder
    private var panel: some View {
        switch model.phase {
        case .home, .search:
            HomePanel(model: model)
        case .place(let place), .planning(let place):
            PlacePanel(model: model, place: place)
        case .preview(let place, let plan):
            RoutePreviewPanel(model: model, place: place, plan: plan)
        case .guiding(let place, let guidance):
            GuidanceBottomView(guidance: guidance, place: place, model: model)
        }
    }

    @ViewBuilder
    private var planningDialog: some View {
        if case .planning(let place) = model.phase {
            VStack(spacing: SbuTheme.space4) {
                ProgressView()
                Text("Cerco un percorso adatto al tuo veicolo")
                    .font(SbuTheme.body)
                    .foregroundStyle(SbuTheme.ink)
                    .multilineTextAlignment(.center)
                SbuButton("Annulla", kind: .secondary) { model.cancelPlanning(back: place) }
            }
            .padding(SbuTheme.space6)
            .background(SbuTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: SbuTheme.radiusLg))
            .padding(SbuTheme.space8)
        }
    }

    @ViewBuilder
    private var problemBanner: some View {
        if let problem = model.problem {
            HStack(alignment: .top, spacing: SbuTheme.space3) {
                Image(systemName: "exclamationmark.circle").foregroundStyle(SbuTheme.danger)
                Text(problem)
                    .font(SbuTheme.subheadline)
                    .foregroundStyle(SbuTheme.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                IconButton(title: "Chiudi", symbol: "xmark") { model.problem = nil }
            }
            .padding(SbuTheme.space3)
            .background(SbuTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: SbuTheme.radiusCard))
            .overlay(RoundedRectangle(cornerRadius: SbuTheme.radiusCard).strokeBorder(SbuTheme.line))
            .padding(.horizontal, SbuTheme.space4)
        }
    }
}
