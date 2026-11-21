import SwiftUI

/// Il tour di benvenuto (alla prima apertura, poi dal menu ❄︎ → Tour di benvenuto…): una pagina alla volta,
/// e in fondo le due cose da provare, che si spuntano mentre le fai.
struct TourView: View {
    /// Chiude la finestra: la passa l'AppDelegate, che la possiede.
    var close: () -> Void = {}
    /// Non privata solo perché i test fotografano ogni pagina (SBU-199).
    @State var page = TourPage.welcome
    private let progress = TourProgress.shared

    var body: some View {
        VStack(alignment: .leading, spacing: Quaderno.space4) {
            Text(verbatim: cartiglio)
                .font(Quaderno.cartiglioFont)
                .tracking(Quaderno.cartiglioSize * Quaderno.cartiglioTracking)
                .foregroundStyle(Quaderno.inkMuted.color)
            HStack(alignment: .firstTextBaseline, spacing: Quaderno.space4) {
                Image(systemName: page.symbol)
                    .font(.title.weight(.medium))
                    .accessibilityHidden(true)
                Text(page.title)
                    .font(Quaderno.titleFont)
                    .accessibilityAddTraits(.isHeader)
            }
            .foregroundStyle(Quaderno.ink.color)
            Text(page.text)
                .font(.title3)
                .foregroundStyle(Quaderno.ink.color)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            challenges
            Divider()
            buttons
        }
        .padding(Quaderno.space6)
        .frame(width: Quaderno.gridCell * 22, height: Quaderno.gridCell * 16, alignment: .topLeading)
        .background(Quaderno.paper.color)
        .tint(Quaderno.ink.color)
    }

    /// `1 DI 6`: solo metadati, come il cartiglio delle Impostazioni.
    private var cartiglio: String {
        String(localized: "\(page.rawValue + 1) di \(TourPage.allCases.count)").uppercased()
    }

    private var challenges: some View {
        VStack(alignment: .leading, spacing: Quaderno.space1) {
            Text("Da provare adesso")
                .font(.headline)
                .foregroundStyle(Quaderno.ink.color)
            ForEach(TourChallenge.allCases) { challenge in
                let isDone = progress.done.contains(challenge)
                Label {
                    Text(challenge.title)
                        .strikethrough(isDone)
                        .foregroundStyle(isDone ? Quaderno.inkMuted.color : Quaderno.ink.color)
                } icon: {
                    Image(systemName: isDone ? "checkmark.square.fill" : "square")
                        .foregroundStyle(Quaderno.ink.color)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(challenge.title)
                .accessibilityValue(isDone ? Text("Fatto") : Text("Da fare"))
            }
        }
    }

    private var buttons: some View {
        HStack {
            if page != TourPage.allCases.last {
                Button("Salta il tour", action: close)
            }
            Spacer()
            if let previous = TourPage(rawValue: page.rawValue - 1) {
                Button("Indietro") { page = previous }
            }
            if let next = TourPage(rawValue: page.rawValue + 1) {
                Button("Avanti") { page = next }
                    .keyboardShortcut(.defaultAction)
            } else {
                Button("Inizia", action: close)
                    .keyboardShortcut(.defaultAction)
            }
        }
    }
}

#Preview("Chiaro") {
    TourView().preferredColorScheme(.light)
}

#Preview("Scuro") {
    TourView().preferredColorScheme(.dark)
}
