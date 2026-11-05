import FamilyControls
import SbuKit
import SwiftUI

/// The App consentite: the apps that stay open during Blocca ora and the Sessioni, chosen in the
/// system picker. Screen Time takes at most 50.
struct AllowListCard: View {
    let shield: ShieldModel
    @State private var isPicking = false
    @State private var picked = FamilyActivitySelection(includeEntireCategory: true)
    @State private var isTooMany = false

    var body: some View {
        VStack(alignment: .leading, spacing: SbuTheme.space2) {
            Button("App consentite: \(shield.settings.allowList.applicationTokens.count) su \(ShieldSettings.maxAllowed)", action: pick)
            (isTooMany ? Text("Al massimo \(ShieldSettings.maxAllowed) app: scegline di meno.") : Text("Restano aperte durante Blocca ora e le Sessioni."))
                .font(SbuTheme.footnote)
                .foregroundStyle(SbuTheme.inkMuted)
        }
        .font(SbuTheme.body)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SbuTheme.space4)
        .background(SbuTheme.surfaceRaised, in: .rect(cornerRadius: SbuTheme.radiusCard))
        .overlay {
            RoundedRectangle(cornerRadius: SbuTheme.radiusCard)
                .strokeBorder(SbuTheme.line, lineWidth: SbuTheme.hairline)
        }
        .familyActivityPicker(isPresented: $isPicking, selection: $picked)
        .onChange(of: isPicking) {
            if !isPicking { take(picked) }
        }
    }

    private func pick() {
        Task {
            guard await shield.authorize() else { return }
            // A category chosen whole counts as its apps, which is what Screen Time's exceptions take.
            var selection = FamilyActivitySelection(includeEntireCategory: true)
            selection.applicationTokens = shield.settings.allowList.applicationTokens
            picked = selection
            isPicking = true
        }
    }

    private func take(_ selection: FamilyActivitySelection) {
        isTooMany = selection.applicationTokens.count > ShieldSettings.maxAllowed
        if !isTooMany { shield.allow(selection) }
    }
}

#Preview("Light") {
    AllowListCard(shield: ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
        .padding()
}

#Preview("Dark") {
    AllowListCard(shield: ShieldModel(defaults: UserDefaults(suiteName: "preview")!, isDemo: true))
        .padding()
        .preferredColorScheme(.dark)
}
