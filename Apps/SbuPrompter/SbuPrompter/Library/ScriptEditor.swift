import SbuKit
import SwiftUI

/// Title, text and the button that sends the script to the prompter.
struct ScriptEditor: View {
    @Bindable var script: Script
    @Environment(AppModel.self) private var model
    @State private var selection: TextSelection?

    var body: some View {
        let parsed = ParsedScript(script.body)
        VStack(alignment: .leading, spacing: 0) {
            TextField("Titolo", text: $script.title)
                .textFieldStyle(.plain)
                .font(SbuTheme.title2)
                .padding(.horizontal, SbuTheme.space5)
                .padding(.top, SbuTheme.space4)
                .padding(.bottom, SbuTheme.space2)
            Divider()
            TextEditor(text: $script.body, selection: $selection)
                .font(SbuTheme.body)
                .scrollContentBackground(.hidden)
                .padding(SbuTheme.space3)
                .accessibilityLabel(Text("Testo del copione"))
            Divider()
            HStack(spacing: SbuTheme.space3) {
                Button("Sezione", systemImage: "number") { insert(.section) }
                    .help(Text("Inserisce un titolo di sezione dove sei: una riga che inizia con #."))
                Button("Interruzione", systemImage: "minus") { insert(.divider) }
                    .help(Text("Inserisce una riga di --- che divide il copione."))
                Spacer()
                Text("\(parsed.words.count) parole · \(parsed.cues.count) sezioni")
                    .font(SbuTheme.caption)
                    .monospacedDigit()
                    .foregroundStyle(SbuTheme.inkMuted)
            }
            .padding(.horizontal, SbuTheme.space5)
            .padding(.vertical, SbuTheme.space2)
        }
        .background(SbuTheme.surfaceRaised)
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
