import SwiftUI

/// Impostazioni → Visitatori (SBU-178): se Yeti e trenino passano da soli. Dal menu ❄︎ → Natale passano sempre.
struct VisitorsSection: View {
    @AppStorage(VisitorKind.yeti.autoKey) private var yeti = true
    @AppStorage(VisitorKind.train.autoKey) private var train = true

    var body: some View {
        Section {
            Toggle("Lo Yeti passa da solo", isOn: $yeti)
            Toggle("Il trenino passa da solo", isOn: $train)
        } header: {
            Text("Visitatori")
        } footer: {
            Text("Lo Yeti passa ogni tanto se c'è un pupazzo e prova a portarlo via: fai clic per scacciarlo. Il trenino con l'elfo lascia un regalo per l'albero o il pupazzo.")
                .foregroundStyle(Quaderno.inkMuted.color)
        }
    }
}

#Preview("Chiaro") {
    Form { VisitorsSection() }
        .formStyle(.grouped)
        .preferredColorScheme(.light)
}

#Preview("Scuro") {
    Form { VisitorsSection() }
        .formStyle(.grouped)
        .preferredColorScheme(.dark)
}
