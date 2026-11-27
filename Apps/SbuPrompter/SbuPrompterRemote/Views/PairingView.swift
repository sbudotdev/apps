import SbuKit
import SwiftUI

/// The first time with a Mac: the 4-digit code shown in Sbu Prompter's menu on the Mac.
struct PairingView: View {
    let mac: String
    let wrong: Bool
    let paused: Bool
    /// Shown when other Macs are around: this one may not be the right Mac.
    var chooseAnother: ChooseAnotherMacButton?
    let onCode: (String) -> Void

    @State private var code = ""
    @FocusState private var isFocused: Bool

    private var cartiglio: String { ["Sbu", "Prompter", mac].joined(separator: " · ") }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SbuTheme.space6) {
                SbuScreenTitle("Abbina il Mac", cartiglio: cartiglio)
                Text("Scrivi il codice di 4 cifre che trovi nel menu di Sbu Prompter, nella barra dei menu del Mac.")
                    .font(SbuTheme.body)
                    .foregroundStyle(SbuTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
                TextField("Codice", text: $code)
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .font(.title.monospacedDigit())
                    .padding(SbuTheme.space3)
                    .background(SbuTheme.surfaceRaised, in: .rect(cornerRadius: SbuTheme.radiusCard))
                    .overlay(RoundedRectangle(cornerRadius: SbuTheme.radiusCard).strokeBorder(SbuTheme.line))
                    .focused($isFocused)
                    .accessibilityIdentifier("pairingCode")
                    .onChange(of: code) { _, new in
                        let digits = String(new.filter(\.isNumber).prefix(4))
                        if digits != new { code = digits }
                        if digits.count == 4 { onCode(digits) }
                    }
                if paused {
                    Label("Troppi codici sbagliati: il Mac ne mostra uno nuovo e per un po' non accetta codici. Aspetta, oppure scegli Dimentica gli iPhone abbinati nel menu del Mac.",
                          systemImage: "hourglass")
                        .font(SbuTheme.body)
                        .foregroundStyle(SbuTheme.danger)
                } else if wrong {
                    Label("Codice sbagliato. Dopo 5 tentativi il Mac ne mostra uno nuovo.", systemImage: "exclamationmark.triangle")
                        .font(SbuTheme.body)
                        .foregroundStyle(SbuTheme.danger)
                }
                chooseAnother
            }
            .padding(SbuTheme.space4)
        }
        .onAppear { isFocused = true }
    }
}

#Preview("Light") {
    NavigationStack { PairingView(mac: "MacBook di Matteo", wrong: true, paused: false) { _ in } }
        .tint(SbuTheme.ink)
}

#Preview("Dark") {
    NavigationStack { PairingView(mac: "MacBook di Matteo", wrong: false, paused: false) { _ in } }
        .tint(SbuTheme.ink)
        .preferredColorScheme(.dark)
}
