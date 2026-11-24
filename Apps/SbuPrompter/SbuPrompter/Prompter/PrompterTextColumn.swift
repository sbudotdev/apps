import SbuKit
import SwiftUI

/// The script's lines, measured so the controller knows where each one sits.
/// Kept apart from the offset so scrolling doesn't re-lay out the text.
struct PrompterTextColumn: View {
    let controller: PrompterController
    let settings: PrompterSettings
    let width: CGFloat
    let viewportHeight: CGFloat
    /// False for the settings preview: it draws the same text but must not move the real prompter.
    var reportsLayout = true

    @State private var lineOffsets: [Int: CGFloat] = [:]
    @State private var contentHeight: CGFloat = 0

    var body: some View {
        let lines = controller.script.lines
        VStack(alignment: .leading, spacing: settings.fontSize * 0.35) {
            ForEach(lines.indices, id: \.self) { index in
                line(lines[index], index: index)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named("column")).minY } action: { lineOffsets[index] = $0 }
            }
            if !controller.script.words.isEmpty {
                // The end of the text: the script closes on its full stop.
                SbuFullStop(.set, size: .inline)
                    .padding(.top, settings.fontSize * 0.35)
                    .accessibilityHidden(true)
            }
        }
        // Room after the last line so it can reach the reading line.
        .padding(.bottom, viewportHeight * 0.6)
        .frame(width: width, alignment: .topLeading)
        .fixedSize(horizontal: false, vertical: true)
        .coordinateSpace(.named("column"))
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
        .onChange(of: lineOffsets) { report() }
        .onChange(of: contentHeight) { report() }
        .onChange(of: viewportHeight) { report() }
        .onChange(of: lines.count) { lineOffsets = lineOffsets.filter { $0.key < lines.count } }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func line(_ line: ParsedScript.Line, index: Int) -> some View {
        switch line.kind {
        case .heading:
            Text(verbatim: line.text.uppercased())
                .font(.system(size: settings.fontSize * 0.5, weight: .semibold))
                .tracking(1)
                .foregroundStyle(SbuTheme.inkMuted)
                .accessibilityAddTraits(.isHeader)
        case .separator:
            Rectangle()
                .fill(SbuTheme.line)
                .frame(height: 1)
                .padding(.vertical, settings.fontSize * 0.25)
        case .text:
            Text(attributed(line))
                .font(.system(size: settings.fontSize, weight: .medium))
                .lineSpacing(settings.fontSize * 0.15)
        }
    }

    /// In voice mode the words already read fade to the muted ink.
    private func attributed(_ line: ParsedScript.Line) -> AttributedString {
        var result = AttributedString()
        let read = controller.mode == .voice ? controller.readWordCount - line.wordRange.lowerBound : 0
        var wordIndex = 0
        for (offset, token) in TextNormalizer.tokens(in: line.text).enumerated() {
            var piece = AttributedString((offset == 0 ? "" : " ") + token.text)
            let isRead = wordIndex < read
            piece.foregroundColor = isRead ? SbuTheme.inkMuted : textColor
            if !token.normalized.isEmpty { wordIndex += 1 }
            result += piece
        }
        return result
    }

    private var textColor: Color {
        switch settings.textColor {
        case .ink: SbuTheme.ink
        case .muted: SbuTheme.inkMuted
        case .accent: SbuAccent.prompter.base
        }
    }

    private func report() {
        guard reportsLayout else { return }
        let offsets = (0..<controller.script.lines.count).map { Double(lineOffsets[$0] ?? 0) }
        controller.setLayout(lineOffsets: offsets, contentHeight: contentHeight, viewportHeight: viewportHeight)
    }
}
