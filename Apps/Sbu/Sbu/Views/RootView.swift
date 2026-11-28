import SbuKit
import SwiftUI

/// Sbu inside the standard shell: the notebook is the tool screen, settings are the shared ones.
struct RootView: View {
    @State private var notebook = Notebook()
    @State private var openTool: Tool?
    @State private var isEditing = false

    var body: some View {
        SbuAppShell("Sbu", slug: "sbu", accent: SbuAccent(base: SbuTheme.ink, onInk: SbuTheme.paper),
                    appIcon: Image(.sbuArtwork)) {
            HomeView(notebook: notebook, open: { openTool = $0 }, edit: { isEditing = true })
        } settings: {
            EmptyView()
        }
        .fullScreenCover(item: $openTool) { tool in
            ToolPage(tool: tool)
        }
        .sheet(isPresented: $isEditing) {
            ToolsSheet(notebook: notebook)
        }
        .onOpenURL { url in
            openTool = Tool(url: url)
        }
    }
}

#Preview("Light") {
    RootView()
}

#Preview("Dark") {
    RootView()
        .preferredColorScheme(.dark)
}
