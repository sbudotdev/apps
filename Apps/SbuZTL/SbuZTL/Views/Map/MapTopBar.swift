import SbuKit
import SwiftUI

/// Settings on the left, the moment and the vehicle on the right: the two things every answer depends on.
struct MapTopBar: View {
    @Environment(\.showSettings) private var showSettings
    @Bindable var model: MapModel
    @State private var isPickingTime = false
    @State private var isAddingVehicle = false

    private var momentTitle: Text {
        guard let departure = model.departure else { return Text("Adesso") }
        return Text(departure.formatted(Date.FormatStyle(timeZone: Holidays.calendar.timeZone).weekday(.abbreviated).day().hour().minute()))
    }

    var body: some View {
        HStack(spacing: SbuTheme.space2) {
            Button("Impostazioni", systemImage: "line.3.horizontal") { showSettings() }
                .labelStyle(.iconOnly)
                .fontWeight(.medium)
                .mapPill()
            Spacer(minLength: 0)
            Button {
                isPickingTime = true
            } label: {
                Label { momentTitle } icon: { Image(systemName: "clock") }
                    .lineLimit(1)
            }
            .mapPill()
            .tourAnchor(.moment)
            vehicleMenu
                .tourAnchor(.vehicle)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $isPickingTime) {
            TimePickerSheet(departure: $model.departure)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $isAddingVehicle) {
            VehicleWizard(store: model.store)
        }
    }

    private var vehicleMenu: some View {
        Menu {
            ForEach(model.store.state.vehicles) { vehicle in
                Button {
                    model.store.state.selectedVehicleID = vehicle.id
                } label: {
                    if vehicle.id == model.store.vehicle.id {
                        Label(vehicle.nickname, systemImage: "checkmark")
                    } else {
                        Text(vehicle.nickname)
                    }
                }
            }
            Button("Aggiungi veicolo", systemImage: "plus") { isAddingVehicle = true }
        } label: {
            Label {
                if model.store.hasVehicle {
                    Text(model.store.vehicle.nickname)
                } else {
                    Text("Aggiungi")
                }
            } icon: {
                Image(systemName: model.store.vehicle.kind.symbol)
            }
            .lineLimit(1)
            .frame(maxWidth: 140)
            .mapPill()
        }
        .accessibilityLabel(Text("Veicolo"))
        .accessibilityValue(model.store.hasVehicle ? Text(model.store.vehicle.nickname) : Text("Nessuno"))
    }
}
