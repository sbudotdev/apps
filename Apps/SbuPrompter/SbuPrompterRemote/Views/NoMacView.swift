import SbuKit
import SwiftUI

/// No Mac joined: how to connect one, and the Macs nearby when there is more than one to choose.
struct NoMacView: View {
    let model: RemoteModel

    private var cartiglio: String {
        ["Sbu", "Prompter", String(localized: "Nessun Mac")].joined(separator: " · ")
    }

    var body: some View {
        GeometryReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: SbuTheme.space6) {
                    SbuScreenTitle("Telecomando", cartiglio: cartiglio)
                    SbuEmpty(sentence: sentence) {
                        status
                    }
                    if model.phase == .searching, model.macs.count > 1 {
                        VStack(alignment: .leading, spacing: SbuTheme.space3) {
                            ForEach(model.macs, id: \.self) { mac in
                                Button(mac, systemImage: "laptopcomputer") { model.choose(mac) }
                                    .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                .padding(SbuTheme.space4)
                .frame(maxWidth: .infinity, minHeight: proxy.size.height, alignment: .top)
                .sbuPaper(grid: true)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(SbuTheme.paper)
    }

    private var sentence: LocalizedStringKey {
        if model.phase == .outdated {
            return "Il Mac usa un'altra versione di Sbu Prompter. Aggiorna l'app sul Mac e sull'iPhone."
        }
        return "Apri Sbu Prompter sul Mac e tieni l'iPhone sulla stessa Wi-Fi. Il Mac compare qui da solo."
    }

    @ViewBuilder private var status: some View {
        if case .connecting(let mac) = model.phase {
            VStack(alignment: .leading, spacing: SbuTheme.space3) {
                ProgressView {
                    Text("Collegamento a \(mac)")
                }
                .controlSize(.small)
                if model.macs.count > 1 {
                    ChooseAnotherMacButton(model: model)
                }
            }
        } else if model.phase == .searching, model.macs.count == 1, let mac = model.macs.first {
            Button("Collega \(mac)", systemImage: "laptopcomputer") { model.choose(mac) }
                .buttonStyle(.bordered)
        }
    }
}

/// Back to the list, when the Mac being joined is not the one in front of the person.
struct ChooseAnotherMacButton: View {
    let model: RemoteModel

    var body: some View {
        Button("Scegli un altro Mac", systemImage: "list.bullet") { model.chooseAnother() }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("chooseAnotherMac")
    }
}

#Preview("Light") {
    NavigationStack { NoMacView(model: RemoteModel()) }
        .tint(SbuTheme.ink)
}

#Preview("Dark") {
    NavigationStack { NoMacView(model: RemoteModel()) }
        .tint(SbuTheme.ink)
        .preferredColorScheme(.dark)
}
