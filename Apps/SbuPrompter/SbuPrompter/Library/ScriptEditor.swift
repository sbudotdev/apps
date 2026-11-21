import SbuKit
import SwiftUI

/// Title, text and the button that sends the script to the prompter.
struct ScriptEditor: View {
    @Bindable var script: Script
    @Environment(AppModel.self) private var model

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
            TextEditor(text: $script.body)
                .font(SbuTheme.body)
                .scrollContentBackground(.hidden)
                .padding(SbuTheme.space3)
                .accessibilityLabel(Text("Testo del copione"))
            Divider()
            HStack(spacing: SbuTheme.space3) {
                Text("Righe che iniziano con # o una riga di --- dividono il copione in sezioni.")
                    .font(SbuTheme.caption)
                    .foregroundStyle(SbuTheme.inkMuted)
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
}
