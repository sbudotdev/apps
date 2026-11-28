import LevelTool
import MoonTool
import SbuKit
import SubscriptionsTool
import SwiftUI

/// A tool full screen, as its own app shows it, under a strip that goes back to the notebook.
/// A strip above the tool, as Social's platforms (ADR-0017): it never covers the tool's own back button.
struct ToolPage: View {
    let tool: Tool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        // A stack, not a safe area inset: the tool's navigation bar would stay under the strip.
        VStack(spacing: 0) {
            HStack {
                Button("Quaderno", systemImage: "chevron.backward") { dismiss() }
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal, SbuTheme.space4)
            .padding(.vertical, SbuTheme.space2)
            .tint(SbuTheme.ink)
            content
        }
        .background(SbuTheme.paper)
    }

    @ViewBuilder private var content: some View {
        switch tool {
        case .level: LevelTool()
        case .moon: MoonTool()
        case .subscriptions: SubscriptionsTool()
        }
    }
}

#Preview("Light") {
    ToolPage(tool: .moon)
}

#Preview("Dark") {
    ToolPage(tool: .moon)
        .preferredColorScheme(.dark)
}
