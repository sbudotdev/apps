import AppKit
import UniformTypeIdentifiers

/// «Manda…» (SBU-200): scrive l'oggetto in un file `.sbuseasons` e apre il menu di condivisione di macOS
/// (AirDrop, Messaggi, Mail…), con in più «Salva…» per metterlo dove vuoi. Niente rete nostra: lo manda macOS.
final class ToySharing: NSObject, NSSharingServicePickerDelegate {
    static let shared = ToySharing()
    /// Il menu aperto: tenuto qui finché macOS lo usa.
    private var picker: NSSharingServicePicker?

    /// Apre il menu sotto `view`. Il file sta nella cartella temporanea, che macOS svuota da sé.
    func share(_ toy: ToyFile, from view: NSView) {
        let folder = FileManager.default.temporaryDirectory.appending(path: "Manda")
        guard let url = try? toy.write(in: folder) else {
            NSSound.beep()
            return
        }
        let picker = NSSharingServicePicker(items: [url])
        picker.delegate = self
        self.picker = picker
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }

    func sharingServicePicker(_ sharingServicePicker: NSSharingServicePicker, sharingServicesForItems items: [Any],
                              proposedSharingServices proposedServices: [NSSharingService]) -> [NSSharingService] {
        guard let url = items.first as? URL else { return proposedServices }
        let image = NSImage(systemSymbolName: "square.and.arrow.down", accessibilityDescription: nil) ?? NSImage()
        let save = NSSharingService(title: String(localized: "Salva…"), image: image, alternateImage: nil) { [weak self] in
            self?.save(url)
        }
        return proposedServices + [save]
    }

    private func save(_ url: URL) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = url.lastPathComponent
        panel.allowedContentTypes = [UTType(exportedAs: ToyFile.typeIdentifier)]
        NSApp.activate()
        guard panel.runModal() == .OK, let target = panel.url else { return }
        do {
            try Self.place(url, at: target)
        } catch {
            NSAlert(error: error).runModal()
        }
    }

    /// Mette una copia di `url` in `target`. Se `target` c'è già (la sostituzione l'ha confermata il pannello)
    /// lo scambia in un colpo solo: se qualcosa va storto, il file di prima resta.
    static func place(_ url: URL, at target: URL) throws {
        let files = FileManager.default
        guard files.fileExists(atPath: target.path) else {
            try files.copyItem(at: url, to: target)
            return
        }
        // La copia sta sullo stesso disco di `target` (chiavetta, disco esterno): replaceItemAt non scambia tra due dischi.
        let folder = try files.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: target, create: true)
        defer { try? files.removeItem(at: folder) }
        let copy = folder.appending(path: target.lastPathComponent)
        try files.copyItem(at: url, to: copy)
        _ = try files.replaceItemAt(target, withItemAt: copy)
    }
}
