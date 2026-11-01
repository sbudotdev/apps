import SbuKit
import SwiftUI

/// Adds or edits a vehicle one question at a time: name, type, fuel, class, review.
struct VehicleWizard: View {
    private enum Step { case name, kind, fuel, euro, review }

    @Environment(\.dismiss) private var dismiss
    let store: AppStore
    var editing: Vehicle?
    var onSaved: () -> Void = {}

    @State private var step = Step.name
    @State private var nickname = ""
    @State private var kind = VehicleKind.car
    @State private var fuel = Fuel.petrol
    @State private var euro: EuroClass?
    @FocusState private var isNameFocused: Bool

    private var availableFuels: [Fuel] { kind == .car ? Fuel.allCases : [.petrol, .diesel, .electric] }
    private var availableClasses: [EuroClass] {
        fuel == .diesel && kind == .car ? EuroClass.allCases : EuroClass.allCases.filter { $0 != .euro6abc }
    }

    private var canContinue: Bool {
        switch step {
        case .name: !nickname.trimmingCharacters(in: .whitespaces).isEmpty
        case .euro: euro != nil
        default: true
        }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: SbuTheme.space4) {
                Text(title)
                    .font(SbuTheme.title2)
                    .foregroundStyle(SbuTheme.ink)
                ScrollView { stepContent }
                    .scrollBounceBehavior(.basedOnSize)
                SbuButton(step == .review ? "Salva il veicolo" : "Continua", action: advance)
                    .disabled(!canContinue)
                    .opacity(canContinue ? 1 : 0.5)
                    .accessibilityIdentifier("continue")
            }
            .padding(SbuTheme.space4)
            .background(SbuTheme.paper)
            .navigationTitle(editing == nil ? "Aggiungi veicolo" : "Modifica veicolo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi", systemImage: "xmark") { dismiss() }
                }
                if step != .name {
                    ToolbarItem(placement: .navigation) {
                        Button("Indietro", systemImage: "chevron.left", action: back)
                    }
                }
            }
        }
        .interactiveDismissDisabled(!nickname.isEmpty)
        .onAppear(perform: prefill)
    }

    private var title: LocalizedStringKey {
        switch step {
        case .name: "Come lo chiami?"
        case .kind: "Che veicolo è?"
        case .fuel: "Come è alimentato?"
        case .euro: "Che classe Euro ha?"
        case .review: "Controlla il tuo veicolo"
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .name:
            VStack(alignment: .leading, spacing: SbuTheme.space2) {
                TextField("Per esempio Panda", text: $nickname)
                    .focused($isNameFocused)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.next)
                    .onSubmit { if canContinue { advance() } }
                    .onChange(of: nickname) { _, new in
                        if new.count > 40 { nickname = String(new.prefix(40)) }
                    }
                    .onAppear { isNameFocused = true }
                Text("La classe Euro è sul libretto, al campo V.9. Non chiedo la targa: resta tutto sul tuo iPhone.")
                    .font(SbuTheme.footnote)
                    .foregroundStyle(SbuTheme.inkMuted)
            }
        case .kind:
            choices(VehicleKind.allCases, selected: kind) { kind = $0 } label: { String(localized: $0.title) } symbol: { $0.symbol }
        case .fuel:
            choices(availableFuels, selected: fuel) { fuel = $0 } label: { String(localized: $0.title) } symbol: { _ in nil }
        case .euro:
            choices(availableClasses, selected: euro) { euro = $0 } label: { $0.title } symbol: { _ in nil }
        case .review:
            VStack(spacing: SbuTheme.space2) {
                review("Nome", value: nickname, step: .name)
                review("Veicolo", value: String(localized: kind.title), step: .kind)
                review("Alimentazione", value: String(localized: fuel.title), step: .fuel)
                if fuel != .electric {
                    review("Classe Euro", value: euro?.title ?? "", step: .euro)
                }
            }
        }
    }

    private func choices<Option: Identifiable & Equatable>(_ options: [Option], selected: Option?, select: @escaping (Option) -> Void,
                                                           label: @escaping (Option) -> String, symbol: @escaping (Option) -> String?) -> some View {
        VStack(spacing: SbuTheme.space2) {
            ForEach(options) { option in
                Button {
                    select(option)
                } label: {
                    ChoiceTile(title: label(option), symbol: symbol(option), isSelected: option == selected)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func review(_ title: LocalizedStringKey, value: String, step: Step) -> some View {
        Button {
            self.step = step
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(SbuTheme.footnote).foregroundStyle(SbuTheme.inkMuted)
                    Text(value).font(SbuTheme.body).foregroundStyle(SbuTheme.ink)
                }
                Spacer()
                Image(systemName: "pencil").foregroundStyle(SbuTheme.ink)
                    .accessibilityHidden(true)
            }
            .padding(SbuTheme.space3)
            .background(SbuTheme.surfaceRaised, in: RoundedRectangle(cornerRadius: SbuTheme.radiusCard))
            .overlay(RoundedRectangle(cornerRadius: SbuTheme.radiusCard).strokeBorder(SbuTheme.line))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func prefill() {
        guard let editing, nickname.isEmpty else { return }
        nickname = editing.nickname
        kind = editing.kind
        fuel = editing.fuel
        euro = editing.euro
        step = .review
    }

    private func advance() {
        switch step {
        case .name: step = .kind
        case .kind:
            if !availableFuels.contains(fuel) { fuel = .petrol }
            step = .fuel
        case .fuel:
            if fuel == .electric {
                euro = nil
                step = .review
            } else {
                if let euro, !availableClasses.contains(euro) { self.euro = nil }
                step = .euro
            }
        case .euro: step = .review
        case .review: saveVehicle()
        }
    }

    private func back() {
        switch step {
        case .name: break
        case .kind: step = .name
        case .fuel: step = .kind
        case .euro: step = .fuel
        case .review: step = fuel == .electric ? .fuel : .euro
        }
    }

    private func saveVehicle() {
        var vehicle = editing ?? Vehicle(nickname: nickname, kind: kind, fuel: fuel, euro: euro)
        vehicle.nickname = nickname.trimmingCharacters(in: .whitespaces)
        vehicle.kind = kind
        vehicle.fuel = fuel
        vehicle.euro = fuel == .electric ? nil : euro
        store.save(vehicle)
        onSaved()
        dismiss()
    }
}

#Preview("Light") {
    VehicleWizard(store: AppStore(url: nil))
}

#Preview("Dark") {
    VehicleWizard(store: AppStore(url: nil)).preferredColorScheme(.dark)
}
