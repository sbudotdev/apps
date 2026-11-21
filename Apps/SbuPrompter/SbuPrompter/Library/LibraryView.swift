import SbuKit
import SwiftData
import SwiftUI

/// The library window: every script on the left, the editor on the right.
struct LibraryView: View {
    static let windowID = "library"

    @Environment(AppModel.self) private var model
    @Environment(\.modelContext) private var context
    @Query(sort: \Script.updatedAt, order: .reverse) private var scripts: [Script]
    @State private var selection: UUID?
    @State private var isImporting = false
    @State private var importFailed = false
    @State private var scriptToDelete: Script?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(scripts) { script in
                    LibraryRow(script: script, isActive: script.id == model.activeScriptID)
                        .tag(script.id)
                        .contextMenu {
                            Button("Leggi nel prompter") { model.read(script) }
                            Button("Elimina…", role: .destructive) { scriptToDelete = script }
                        }
                }
            }
            .scrollContentBackground(.hidden)
            .background(SbuTheme.paper)
            .navigationSplitViewColumnWidth(min: 200, ideal: 240)
            .toolbar {
                ToolbarItemGroup {
                    Button("Nuovo copione", systemImage: "square.and.pencil", action: newScript)
                    Button("Importa…", systemImage: "square.and.arrow.down") { isImporting = true }
                    Button("Incolla come copione", systemImage: "doc.on.clipboard", action: pasteScript)
                }
            }
        } detail: {
            if let script = scripts.first(where: { $0.id == selection }) {
                ScriptEditor(script: script)
                    .id(script.id)
            } else {
                SbuEmpty(sentence: "Scrivi o importa un copione da leggere.") {
                    Button("Nuovo copione", action: newScript)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(SbuTheme.paper)
            }
        }
        .navigationTitle("Libreria")
        .fileImporter(isPresented: $isImporting, allowedContentTypes: ScriptImporter.types, allowsMultipleSelection: true) { result in
            importFiles(result)
        }
        .alert("Non riesco a leggere il file.", isPresented: $importFailed) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Sbu Prompter importa file .txt, .md e .rtf.")
        }
        .confirmationDialog("Eliminare il copione?", isPresented: isConfirmingDelete, presenting: scriptToDelete) { script in
            Button("Elimina", role: .destructive) { delete(script) }
            Button("Annulla", role: .cancel) { scriptToDelete = nil }
        } message: { script in
            Text("«\(script.title)» sparisce dalla libreria di questo Mac.")
        }
        .onAppear {
            if selection == nil { selection = model.activeScriptID ?? scripts.first?.id }
        }
        .onDeleteCommand {
            scriptToDelete = scripts.first { $0.id == selection }
        }
    }

    private var isConfirmingDelete: Binding<Bool> {
        Binding { scriptToDelete != nil } set: { if !$0 { scriptToDelete = nil } }
    }

    private func newScript() {
        insert(Script(title: String(localized: "Nuovo copione"), body: ""))
    }

    private func pasteScript() {
        guard let text = NSPasteboard.general.string(forType: .string), !text.isEmpty else { return }
        insert(Script(title: ScriptImporter.title(fromText: text) ?? String(localized: "Copione incollato"), body: text))
    }

    private func importFiles(_ result: Result<[URL], any Error>) {
        guard case .success(let urls) = result else { importFailed = true; return }
        for url in urls {
            let scoped = url.startAccessingSecurityScopedResource()
            defer { if scoped { url.stopAccessingSecurityScopedResource() } }
            do {
                let imported = try ScriptImporter.read(url)
                insert(Script(title: imported.title, body: imported.body))
            } catch {
                importFailed = true
            }
        }
    }

    private func insert(_ script: Script) {
        context.insert(script)
        try? context.save()
        selection = script.id
    }

    private func delete(_ script: Script) {
        let id = script.id
        context.delete(script)
        try? context.save()
        scriptToDelete = nil
        model.scriptDeleted(id)
        if selection == id { selection = scripts.first { $0.id != id }?.id }
    }
}
