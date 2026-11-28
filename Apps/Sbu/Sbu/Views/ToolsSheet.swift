import SbuKit
import SwiftUI

/// Strumenti: the pages you keep, to reorder or take out, and the tools you can add.
struct ToolsSheet: View {
    let notebook: Notebook

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Nel quaderno") {
                    ForEach(notebook.tools) { tool in
                        Label { Text(tool.name) } icon: { Image(systemName: tool.symbol) }
                    }
                    .onDelete(perform: notebook.remove)
                    .onMove(perform: notebook.move)
                }
                if !notebook.available.isEmpty {
                    Section("Da aggiungere") {
                        ForEach(notebook.available) { tool in
                            Button {
                                notebook.add(tool)
                            } label: {
                                Label { Text(tool.name) } icon: { Image(systemName: "plus.circle.fill") }
                            }
                            .accessibilityHint(Text(tool.summary))
                            .accessibilityIdentifier("add.\(tool.rawValue)")
                        }
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Strumenti")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fine") { dismiss() }
                }
            }
        }
        .tint(SbuTheme.ink)
    }
}

#Preview("Light") {
    ToolsSheet(notebook: .preview)
}

#Preview("Dark") {
    ToolsSheet(notebook: .preview)
        .preferredColorScheme(.dark)
}
