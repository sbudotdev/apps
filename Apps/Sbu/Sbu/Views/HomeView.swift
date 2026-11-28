import SbuKit
import SwiftUI

/// The notebook: how many tools you keep, one row each, and the button that changes them.
struct HomeView: View {
    let notebook: Notebook
    let open: (Tool) -> Void
    let edit: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SbuTheme.space6) {
                SbuScreenTitle("Quaderno", cartiglio: ["Sbu", String(localized: "Quaderno")].joined(separator: " · "))
                if notebook.tools.isEmpty {
                    SbuEmpty(sentence: "Aggiungi gli strumenti che usi: ognuno è una pagina del quaderno.") {
                        Button("Aggiungi strumenti", action: edit)
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    SbuFigure(value: notebook.tools.count.formatted(), context: Text(countWord),
                              accessibilityLabel: Text(spokenCount))
                    SbuListCard(notebook.tools) { tool in
                        ToolRow(tool: tool) { open(tool) }
                    }
                    Button("Modifica strumenti", systemImage: "slider.horizontal.3", action: edit)
                        .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, SbuTheme.space4)
            .padding(.bottom, SbuTheme.space6)
        }
        .sbuPaper()
    }

    private var countWord: LocalizedStringResource {
        notebook.tools.count == 1 ? "strumento" : "strumenti"
    }

    private var spokenCount: String {
        "\(notebook.tools.count.formatted()) \(String(localized: countWord))"
    }
}

#Preview("Light") {
    NavigationStack {
        HomeView(notebook: .preview, open: { _ in }, edit: {})
    }
}

#Preview("Dark") {
    NavigationStack {
        HomeView(notebook: .preview, open: { _ in }, edit: {})
    }
    .preferredColorScheme(.dark)
}
