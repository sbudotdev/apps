import AppKit
import SwiftUI
import UniformTypeIdentifiers

/// Impostazioni → Le tue immagini (SBU-230): importa fino a 10 immagini, scegli quali cadono e come.
struct ImagesSection: View {
    @Bindable private var settings = Settings.shared
    private let library: ImageLibrary
    @State private var failure: String?

    init(library: ImageLibrary = .shared) { self.library = library }

    var body: some View {
        Section {
            ForEach(Array(library.names.enumerated()), id: \.element) { index, name in
                row(name, number: index + 1)
            }
            LabeledContent {
                Button("Importa immagini…", action: pick)
                    .disabled(library.names.count >= Tuning.imagesMax)
            } label: {
                Text("\(library.names.count) di \(Tuning.imagesMax)")
                    .monospacedDigit()
                    .foregroundStyle(Quaderno.inkMuted.color)
            }
            Picker("Come cadono", selection: $settings.values.imagesMotion) {
                Text("Come la neve").tag(ImageMotion.snow)
                Text("Come le foglie").tag(ImageMotion.leaves)
                Text("Come la pioggia").tag(ImageMotion.rain)
            }
        } header: {
            Text("Le tue immagini")
        } footer: {
            Text("Cadono con l'effetto Le tue immagini, al posto dei fiocchi. PNG, JPEG, HEIC o SVG fino a 20 MB: l'app ne tiene una copia sul Mac e non le manda da nessuna parte. Ripristina non le cancella.")
                .foregroundStyle(Quaderno.inkMuted.color)
        }
        .alert("Immagine non importata", isPresented: Binding { failure != nil } set: { if !$0 { failure = nil } }) {
            Button("OK") {}
        } message: {
            Text(failure ?? "")
        }
    }

    /// Una riga: la miniatura, la casella (cade o no) e il tasto per toglierla.
    private func row(_ name: String, number: Int) -> some View {
        HStack(spacing: Quaderno.space4) {
            Toggle(isOn: Binding {
                !settings.values.imagesOff.contains(name)
            } set: { on in
                settings.values.imagesOff.removeAll { $0 == name }
                if !on { settings.values.imagesOff.append(name) }
            }) {
                HStack(spacing: Quaderno.space4) {
                    thumbnail(name)
                    Text("Immagine \(number)")
                }
            }
            .toggleStyle(.checkbox)
            Spacer()
            Button {
                library.remove(name)
                settings.values.imagesOff.removeAll { $0 == name }
            } label: {
                Image(systemName: "trash")
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderless)
            .help(Text("Togli l'immagine \(number)"))
            .accessibilityLabel(Text("Togli l'immagine \(number)"))
        }
    }

    private func thumbnail(_ name: String) -> some View {
        Group {
            if let image = library.smallImage(name) {
                Image(decorative: image, scale: 2)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo")
                    .fontWeight(.medium)
                    .foregroundStyle(Quaderno.inkMuted.color)
            }
        }
        .frame(width: Quaderno.gridCell * 1.5, height: Quaderno.gridCell * 1.5)
        .accessibilityHidden(true)
    }

    /// Il selettore dei file di sistema; ogni file scelto si controlla da solo, e i rifiutati si dicono insieme.
    private func pick() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .heic, .svg]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.prompt = String(localized: "Importa")
        guard panel.runModal() == .OK else { return }
        var errors: [String] = []
        for url in panel.urls {
            do {
                try library.importFile(at: url)
            } catch {
                errors.append("\(url.lastPathComponent): \(error.errorDescription ?? "")")
            }
        }
        failure = errors.isEmpty ? nil : errors.joined(separator: "\n")
    }
}

#Preview("Chiaro") {
    Form { ImagesSection() }
        .formStyle(.grouped)
        .preferredColorScheme(.light)
}

#Preview("Scuro") {
    Form { ImagesSection() }
        .formStyle(.grouped)
        .preferredColorScheme(.dark)
}
