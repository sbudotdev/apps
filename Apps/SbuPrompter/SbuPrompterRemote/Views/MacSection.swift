import SbuKit
import SwiftUI

/// Settings: the Mac in use, forgetting it, and how the remote connects.
struct MacSection: View {
    let model: RemoteModel

    var body: some View {
        Section {
            if let mac = model.currentMac {
                LabeledContent("Mac", value: mac)
                if model.isPaired(with: mac) {
                    SbuButton("Dimentica questo Mac", kind: .destructive,
                              confirmationTitle: "Al prossimo collegamento ti servirà il codice.") {
                        model.forget(mac)
                    }
                }
            }
        } header: {
            Text("Mac")
        } footer: {
            Text("Il telecomando parla con Sbu Prompter solo sulla tua Wi-Fi, senza internet. La prima volta chiede il codice che il Mac mostra nel suo menu.")
        }
    }
}

#Preview("Light") {
    Form { MacSection(model: RemoteModel()) }
}

#Preview("Dark") {
    Form { MacSection(model: RemoteModel()) }
        .preferredColorScheme(.dark)
}
