import SwiftUI

/// Impostazioni → Visitatori (SBU-178, SBU-187): chi passa da solo e quanto spesso, e le palle tra pupazzi.
/// Dal menu ❄︎ → Natale passano sempre.
struct VisitorsSection: View {
    @AppStorage(Passages.autoKey) private var santa = true
    @AppStorage(VisitorKind.yeti.autoKey) private var yeti = true
    @AppStorage(VisitorKind.train.autoKey) private var train = true
    @AppStorage(VisitorKind.elves.autoKey) private var elves = true
    @AppStorage(VisitFrequency.key) private var frequency = VisitFrequency.sometimes.rawValue
    @Bindable private var settings = Settings.shared

    var body: some View {
        Section {
            Toggle("Babbo Natale passa da solo", isOn: $santa)
            Toggle("Lo Yeti passa da solo", isOn: $yeti)
            Toggle("Il trenino passa da solo", isOn: $train)
            Toggle("Gli elfi passano da soli", isOn: $elves)
            Picker("Quanto spesso", selection: $frequency) {
                Text("Spesso").tag(VisitFrequency.often.rawValue)
                Text("Ogni tanto").tag(VisitFrequency.sometimes.rawValue)
                Text("Di rado").tag(VisitFrequency.rarely.rawValue)
            }
            Toggle("I pupazzi si tirano palle di neve", isOn: $settings.values.snowballFights)
        } header: {
            Text("Visitatori")
        } footer: {
            Text("Babbo Natale passa da solo dal 1° dicembre al 6 gennaio. Lo Yeti passa se c'è un pupazzo e prova a portarlo via: scaccialo con un clic o colpiscilo con una palla di neve. Il trenino con l'elfo lascia un regalo. Gli elfi passano ogni poche ore e fanno un pupazzo.")
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
