import AppKit
import SwiftUI

/// La schedina «Novità» in cima al menu ❄︎: compare dopo un aggiornamento, si chiude col pulsante
/// o chiudendo il menu, e non torna più (fino alla prossima versione).
@MainActor
final class WhatsNewCard {
    private let defaults: UserDefaults
    private var items: [NSMenuItem] = []

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// All'avvio, prima del tour: alla prima apertura dell'app le novità di questa versione contano come viste.
    func launched(firstRun: Bool) {
        if firstRun { defaults.set(WhatsNew.release(of: SbuSeasonsApp.version), forKey: "whatsNewSeen") }
    }

    /// Mette la schedina in cima al menu, se c'è qualcosa di nuovo.
    func attach(to menu: NSMenu) {
        guard items.isEmpty, let release = WhatsNew.pending(version: SbuSeasonsApp.version,
                                                            seen: defaults.string(forKey: "whatsNewSeen"), firstRun: false)
        else { return }
        let host = NSHostingView(rootView: WhatsNewView(release: release, notes: WhatsNew.notes[release] ?? []) { [weak self, weak menu] in
            self?.dismiss()
            menu?.cancelTracking()
        })
        host.frame.size = host.fittingSize
        let card = NSMenuItem()
        card.view = host
        items = [card, .separator()]
        for (index, item) in items.enumerated() { menu.insertItem(item, at: index) }
    }

    /// Vista una volta: via dal menu e segnata come letta.
    func dismiss() {
        guard !items.isEmpty else { return }
        defaults.set(WhatsNew.release(of: SbuSeasonsApp.version), forKey: "whatsNewSeen")
        items.forEach { $0.menu?.removeItem($0) }
        items = []
    }
}

/// Il contenuto della schedina: titolo con la versione, le righe nuove, il pulsante per chiuderla.
private struct WhatsNewView: View {
    let release: String
    let notes: [String]
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Quaderno.space1) {
            HStack(alignment: .firstTextBaseline) {
                Text("Novità della \(release)")
                    .font(.headline)
                    .foregroundStyle(Quaderno.ink.color)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Chiudi", systemImage: "xmark", action: close)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help(Text("Chiudi le novità"))
            }
            ForEach(notes, id: \.self) { note in
                Label { Text(note) } icon: { Image(systemName: "circle.fill").font(.system(size: 4)) }
                    .font(.callout)
                    .foregroundStyle(Quaderno.ink.color)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Quaderno.space4)
        .frame(width: Quaderno.gridCell * 12, alignment: .leading)
        .background(Quaderno.paper.color, in: .rect(cornerRadius: 6))   // radiusCard, come le anteprime della galleria
        .padding(.horizontal, Quaderno.space1)
        .tint(Quaderno.ink.color)
    }
}

#Preview("Chiaro") {
    WhatsNewView(release: "2.1", notes: WhatsNew.notes["2.1"] ?? []) {}
}

#Preview("Scuro") {
    WhatsNewView(release: "2.1", notes: WhatsNew.notes["2.1"] ?? []) {}
        .preferredColorScheme(.dark)
}
