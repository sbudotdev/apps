import SbuKit
import SwiftUI

/// The app inside the standard Sbu shell, with the settings opened from the map.
struct RootView: View {
    @State private var store: AppStore
    @State private var model: MapModel
    @State private var isAddingFirstVehicle = false
    @State private var isTourRunning = false
    @State private var showsFirstRun: Bool
    @State private var addedVehicle = false

    init(store: AppStore, location: LocationService) {
        _store = State(initialValue: store)
        _model = State(initialValue: MapModel(store: store, location: location))
        _showsFirstRun = State(initialValue: !store.state.hasFinishedIntro)
    }

    var body: some View {
        SbuAppShell("Sbu ZTL", slug: "ztl", accent: .ztl, appIcon: Image(.appIconArtwork), settingsButtonPlacement: .content) {
            MapScreen(model: model, isTourRunning: $isTourRunning)
                .toolbar(.hidden, for: .navigationBar)
                .overlayPreferenceValue(TourAnchorKey.self) { anchors in
                    if isTourRunning {
                        TourOverlay(anchors: anchors, onFinish: finishTour)
                    }
                }
        } settings: {
            RouteSettingsSection(store: store, catalog: model.catalog, replayIntro: replayIntro)
        }
        .overlay {
            if showsFirstRun {
                FirstRunView(onAdd: { isAddingFirstVehicle = true }, onLater: startTour)
            }
        }
        .sheet(isPresented: $isAddingFirstVehicle) {
            VehicleWizard(store: store) { addedVehicle = true }
        }
        .onChange(of: isAddingFirstVehicle) { _, isOpen in
            if !isOpen, addedVehicle { startTour() }
        }
        .sbuClosure($addedVehicle, word: "Aggiunto")
    }

    private func startTour() {
        showsFirstRun = false
        isTourRunning = true
    }

    private func finishTour() {
        isTourRunning = false
        store.state.hasFinishedIntro = true
    }

    private func replayIntro() {
        store.state.hasFinishedIntro = false
        showsFirstRun = true
    }
}

#Preview("Light") {
    RootView(store: AppStore(url: nil), location: LocationService())
}

#Preview("Dark") {
    RootView(store: AppStore(url: nil), location: LocationService()).preferredColorScheme(.dark)
}
