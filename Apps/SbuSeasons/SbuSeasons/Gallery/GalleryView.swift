import AppKit
import SwiftUI

/// La finestra Sfondi (menu ❄︎ → Sfondi…): le anteprime, lo schermo, "Imposta sfondo" e
/// "Lascia il mio schermo com'è". Con l'effetto consigliato acceso, cambia anche la stagione.
struct GalleryView: View {
    @State private var selection = Wallpaper.all[0].id
    @State private var screenName = NSScreen.main?.localizedName ?? ""
    @State private var failure = ""
    @State private var fails = false
    /// Quante volte si è tornati allo sfondo di prima: aggiorna "Lascia il mio schermo com'è".
    @State private var restores = 0
    @AppStorage("galleryUsesEffect") private var usesEffect = true

    private var screen: NSScreen? {
        NSScreen.screens.first { $0.localizedName == screenName } ?? NSScreen.main
    }

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
                Preview(url: wallpaper.url(for: screen?.frame.size ?? CGSize(width: 16, height: 10)))
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(wallpaper.title)
        .accessibilityValue(Text("Effetto consigliato: \(effect.title)"))
        .accessibilityAddTraits(isChosen ? .isSelected : [])
    }

    private var controls: some View {
        HStack(spacing: Quaderno.space4) {
            if NSScreen.screens.count > 1 {
                Picker("Schermo", selection: $screenName) {
                    ForEach(NSScreen.screens, id: \.localizedName) { Text($0.localizedName).tag($0.localizedName) }
                }
                .fixedSize()
            }
            Toggle("Anche l'effetto consigliato", isOn: $usesEffect)
                .fixedSize()
                .help(Text("Con lo sfondo cambia la stagione: \(Seasons.named(chosen.effect).title)."))
            Spacer()
            Button("Lascia il mio schermo com'è", action: restore)
                .disabled(!canRestore)
                .help(Text("Torna lo sfondo che avevi prima della galleria."))
            Button("Imposta sfondo", action: apply)
                .keyboardShortcut(.defaultAction)
        }
    }

    private var canRestore: Bool {
        _ = restores
        return screen.flatMap { WallpaperMemory().original(screen: $0.localizedName) } != nil
    }

    private func apply() {
        guard let screen else { return }
        do {
            try Wallpaper.set(chosen, on: screen)
            if usesEffect { Settings.shared.seasonID = chosen.effect }
            restores += 1   // ora c'è uno sfondo di prima da ripristinare
        } catch {
            failure = error.localizedDescription
            fails = true
        }
    }

    private func restore() {
        guard let screen else { return }
        do {
            try Wallpaper.restore(on: screen)
            restores += 1
        } catch {
            failure = error.localizedDescription
            fails = true
        }
    }
}

/// L'anteprima di uno sfondo, letta in sottofondo la prima volta che compare.
private struct Preview: View {
    let url: URL?
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
            .task(id: url) {
                guard let url else { return }
                image = await Task.detached(priority: .userInitiated) { Thumbnail.make(url) }.value
            }
    }
}
