import SbuKit
import SwiftUI

/// A page of the notebook: the tool's symbol, its name and the one thing it does. It opens the tool.
struct ToolRow: View {
    let tool: Tool
    let open: () -> Void

    @ScaledMetric(relativeTo: .body) private var symbolWidth: CGFloat = 28

    var body: some View {
        Button(action: open) {
            HStack(spacing: SbuTheme.space3) {
                Image(systemName: tool.symbol)
                    .fontWeight(.medium)
                    .imageScale(.medium)
                    .foregroundStyle(SbuTheme.inkMuted)
                    .frame(width: symbolWidth)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 0) {
                    Text(tool.name)
                        .font(SbuTheme.headline)
                        .foregroundStyle(SbuTheme.ink)
                    Text(tool.summary)
                        .font(SbuTheme.subheadline)
                        .foregroundStyle(SbuTheme.inkMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.forward")
                    .font(SbuTheme.footnote.weight(.semibold))
                    .foregroundStyle(SbuTheme.inkMuted)
                    .accessibilityHidden(true)
            }
            .padding(SbuTheme.space4)
            .contentShape(.rect)
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("tool.\(tool.rawValue)")
    }
}

#Preview("Light") {
    ToolRow(tool: .moon) {}
        .padding()
}

#Preview("Dark") {
    ToolRow(tool: .moon) {}
        .padding()
        .preferredColorScheme(.dark)
}
