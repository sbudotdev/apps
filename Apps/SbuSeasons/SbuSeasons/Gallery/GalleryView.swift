import AppKit
import SwiftUI

/// La finestra Sfondi (menu ❄︎ → Sfondi…): le anteprime, lo schermo, "Imposta sfondo" e
/// "Lascia il mio schermo com'è". Con l'effetto consigliato acceso, cambia anche la stagione.
/// Con più schermi si sceglie uno schermo o tutti; le anteprime sono nel momento del giorno scelto.
struct GalleryView: View {
    /// Nel menu degli schermi: tutti insieme, con un clic.
    private static let allScreens = "*"
    @State private var selection = Wallpaper.all[0].id
    @State private var screenKey = NSScreen.main?.wallpaperKey ?? ""
    @Bindable private var prefs = WallpaperPrefs.shared
    @State private var failure = ""
    @State private var fails = false
    /// Quante volte si è tornati allo sfondo di prima: aggiorna "Lascia il mio schermo com'è".
    @State private var restores = 0
    @AppStorage("galleryUsesEffect") private var usesEffect = true

    private var screen: NSScreen? {
        NSScreen.screens.first { $0.wallpaperKey == screenKey } ?? NSScreen.main
    }

    /// Gli schermi su cui va lo sfondo: quello scelto, o tutti.
    private var targets: [NSScreen] {
        screenKey == Self.allScreens ? NSScreen.screens : screen.map { [$0] } ?? []
    }

    private var moment: DayMoment { prefs.choice.moment(at: .now) }

    private var chosen: Wallpaper { Wallpaper.all.first { $0.id == selection } ?? Wallpaper.all[0] }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: Quaderno.gridCell * 8), spacing: Quaderno.space4)],
                          spacing: Quaderno.space4) {
                    ForEach(Wallpaper.all) { wallpaper in
                        card(wallpaper)
                    }
                }
                .padding(Quaderno.space6)
            }
            Divider()
            controls
                .padding(.horizontal, Quaderno.space6)
                .padding(.vertical, Quaderno.space4)
        }
        .background(Quaderno.paper.color)
        .tint(Quaderno.ink.color)
        .frame(minWidth: Quaderno.gridCell * 36, minHeight: Quaderno.gridCell * 22)
        .alert("Lo sfondo non è cambiato", isPresented: $fails) {
            Button("OK") {}
        } message: {
            Text(failure)
        }
    }

    private func card(_ wallpaper: Wallpaper) -> some View {
        let isChosen = wallpaper.id == selection
        let effect = Seasons.named(wallpaper.effect)
        return Button {
            selection = wallpaper.id
        } label: {
            VStack(alignment: .leading, spacing: Quaderno.space1) {
                Preview(url: wallpaper.url(for: screen?.frame.size ?? CGSize(width: 16, height: 10)), moment: moment)
                    .overlay {
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(Quaderno.ink.color, lineWidth: isChosen ? 3 : 0)
                    }
                Text(wallpaper.title)
                    .foregroundStyle(Quaderno.ink.color)
                Label(effect.title, systemImage: effect.symbol)
                    .font(.caption)
                    .foregroundStyle(Quaderno.inkMuted.color)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(wallpaper.title)
        .accessibilityValue(Text("Effetto consigliato: \(effect.title)"))
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }

    /// Due righe: dove e come (schermo, ora del giorno, effetto), poi le azioni.
    private var controls: some View {
        VStack(alignment: .leading, spacing: Quaderno.space4) {
            HStack(spacing: Quaderno.space4) {
                if NSScreen.screens.count > 1 {
                    Picker("Schermo", selection: $screenKey) {
                        Text("Tutti gli schermi").tag(Self.allScreens)
                        Divider()
                        ForEach(NSScreen.screens, id: \.wallpaperKey) { Text($0.localizedName).tag($0.wallpaperKey) }
                    }
                    .fixedSize()
                }
                Picker("Ora del giorno", selection: $prefs.choice) {
                    ForEach(MomentChoice.all, id: \.self) { Text($0.title).tag($0) }
                }
                .fixedSize()
                Toggle("Anche l'effetto consigliato", isOn: $usesEffect)
                    .fixedSize()
                    .help(Text("Con lo sfondo cambia la stagione: \(Seasons.named(chosen.effect).title)."))
            }
            HStack(spacing: Quaderno.space4) {
                Spacer()
                Button("Lascia il mio schermo com'è", action: restore)
                    .disabled(!canRestore)
                    .help(Text("Torna lo sfondo che avevi prima della galleria."))
                Button("Imposta sfondo", action: apply)
                    .keyboardShortcut(.defaultAction)
            }
        }
    }

    private var canRestore: Bool {
        _ = restores
        return targets.contains { WallpaperMemory().original(screen: $0.wallpaperKey) != nil }
    }

    private func apply() {
        let wallpaper = chosen, screens = targets
        Task {
            do {
                // Prima si segna lo sfondo, poi l'effetto: "segue l'effetto" vede già quello nuovo e lo lascia.
                for screen in screens { prefs.chosen[screen.wallpaperKey] = wallpaper.id }
                if usesEffect { Settings.shared.seasonID = wallpaper.effect }
                try await WallpaperDirector.shared.set(wallpaper, on: screens)
                restores += 1   // ora c'è uno sfondo di prima da ripristinare
            } catch {
                failure = error.localizedDescription
                fails = true
            }
        }
    }

    private func restore() {
        do {
            try WallpaperDirector.shared.restore(on: targets)
            restores += 1
        } catch {
            failure = error.localizedDescription
            fails = true
        }
    }
}

/// L'anteprima di uno sfondo nel suo momento del giorno, fatta in sottofondo la prima volta che compare.
private struct Preview: View {
    let url: URL?
    let moment: DayMoment
    @State private var image: CGImage?

    var body: some View {
        Rectangle()
            .fill(Quaderno.inkMuted.color.opacity(0.15))
            .aspectRatio(16 / 10, contentMode: .fit)
            .overlay {
                if let image {
                    Image(decorative: image, scale: 1).resizable().scaledToFill()
                }
            }
            .clipShape(.rect(cornerRadius: 6))
            .task(id: "\(url?.path ?? "")-\(moment.rawValue)") {
                guard let url else { return }
                image = await Task.detached(priority: .userInitiated) { [moment] in Thumbnail.make(url, moment: moment) }.value
            }
    }
}
