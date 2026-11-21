import SwiftUI

/// Le opzioni del salvaschermo (Impostazioni di Sistema → Salvaschermo → Opzioni…).
struct SaverOptionsView: View {
    @State var wallpaperID: String?
    @State var showsEffect: Bool
    let done: (String?, Bool) -> Void

    var body: some View {
        Form {
            Picker(String(localized: "Sfondo", bundle: .seasons), selection: $wallpaperID) {
                Text(String(localized: "Uno diverso ogni volta", bundle: .seasons)).tag(String?.none)
                Divider()
                ForEach(Wallpaper.all) { Text($0.title).tag(Optional($0.id)) }
            }
            Toggle(String(localized: "L'effetto consigliato sopra", bundle: .seasons), isOn: $showsEffect)
            Text(String(localized: "Lo sfondo segue l'ora del Mac: alba, giorno, tramonto, notte.", bundle: .seasons))
                .font(.callout)
                .foregroundStyle(Quaderno.inkMuted.color)
                .fixedSize(horizontal: false, vertical: true)
            HStack {
                Spacer()
                Button(String(localized: "Fine", bundle: .seasons)) { done(wallpaperID, showsEffect) }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Quaderno.space6)
        .frame(width: Quaderno.gridCell * 18)
        .tint(Quaderno.ink.color)
    }
}
