import SbuKit
import SwiftUI

/// Title, text and the button that sends the script to the prompter.
struct ScriptEditor: View {
    @Bindable var script: Script
    @Environment(AppModel.self) private var model
    @State private var selection: TextSelection?

    /// A comfortable line length for writing; the window can be wider.
    private static let textWidth: CGFloat = 680

    var body: some View {
        let parsed = ParsedScript(script.body)
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: SbuTheme.space1) {
                TextField("Titolo", text: $script.title)
                    .textFieldStyle(.plain)
                    .font(.sbuTitle)
                Text(verbatim: cartiglio(parsed))
                    .font(.sbuCartiglio)
                    .textCase(.uppercase)
                    .tracking(SbuTheme.cartiglioSize * SbuTheme.cartiglioTracking)
                    .foregroundStyle(SbuTheme.inkMuted)
                    .monospacedDigit()
            }
            .frame(maxWidth: Self.textWidth, alignment: .leading)
            .padding(.horizontal, SbuTheme.space5)
            .padding(.top, SbuTheme.space5)
            .padding(.bottom, SbuTheme.space3)

            TextEditor(text: $script.body, selection: $selection)
                .font(.title3)
                .lineSpacing(SbuTheme.space1)
                .scrollContentBackground(.hidden)
                .frame(maxWidth: Self.textWidth)
                .padding(.horizontal, SbuTheme.space4)
                .accessibilityLabel(Text("Testo del copione"))

            HStack(spacing: SbuTheme.space2) {
                Button("Sezione", systemImage: "number") { insert(.section) }
                    .help(Text("Inserisce un titolo di sezione dove sei: una riga che inizia con #."))
                Button("Interruzione", systemImage: "minus") { insert(.divider) }
                    .help(Text("Inserisce una riga di --- che divide il copione."))
                Spacer()
            }
            .frame(maxWidth: Self.textWidth)
            .padding(.horizontal, SbuTheme.space5)
            .padding(.vertical, SbuTheme.space3)
        }
        .frame(maxWidth: .infinity)
        .background(SbuTheme.paper)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Leggi nel prompter", systemImage: "play.fill") { model.read(script) }
                    .disabled(parsed.words.isEmpty)
            }
        }
        .onChange(of: script.body) {
            script.updatedAt = .now
            model.scriptChanged(script)
        }
        .onChange(of: script.title) { script.updatedAt = .now }
    }

    /// "Sbu · Prompter · 106 parole · 5 sezioni · 50 sec".
    private func cartiglio(_ parsed: ParsedScript) -> String {
        var parts = ["Sbu", "Prompter", String(localized: "\(parsed.words.count) parole")]
        if !parsed.cues.isEmpty { parts.append(String(localized: "\(parsed.cues.count) sezioni")) }
        if !parsed.words.isEmpty { parts.append(ReadingTime.text(words: parsed.words.count)) }
        return parts.joined(separator: " · ")
    }

    private func insert(_ insertion: ScriptInsertion) {
        let body = script.body
        var offset = body.count
        if case .selection(let range) = selection?.indices, range.upperBound <= body.endIndex {
            offset = body.distance(from: body.startIndex, to: range.upperBound)
        }
        let result = insertion.apply(to: body, at: offset)
        script.body = result.text
        selection = TextSelection(insertionPoint: result.text.index(result.text.startIndex, offsetBy: result.cursor))
    }
}
