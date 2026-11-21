import SbuKit
import SwiftUI

/// The remote: time read as the figure, the line being read under it, the gesture pad and the buttons.
struct ControlView: View {
    let model: RemoteModel
    let mac: String
    @State private var isShowingCues = false

    private var cartiglio: String { ["Sbu", "Prompter", mac].joined(separator: " · ") }
    private var status: PrompterStatus? { model.status }
    private var isPlaying: Bool { status?.isPlaying ?? false }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SbuTheme.space5) {
                SbuScreenTitle("Telecomando", cartiglio: cartiglio)
                SbuFigure(value: elapsed, fullStop: isPlaying ? .waiting : .set, context: context,
                          accessibilityLabel: Text("Tempo di lettura \(elapsed). \(context)"))
                GesturePad(isPlaying: isPlaying) { model.perform($0) }
                transport
                HStack(spacing: SbuTheme.space3) {
                    Button("Riavvolgi", systemImage: "backward.end") { model.perform(.rewind) }
                    Spacer()
                    Button("Sezioni", systemImage: "list.bullet") { isShowingCues = true }
                        .accessibilityIdentifier("cues")
                        .disabled(status?.cueTitles.isEmpty ?? true)
                }
                .buttonStyle(.bordered)
            }
            .padding(SbuTheme.space4)
        }
        .sbuHaptic(.tick, trigger: model.commandCount)
        .sheet(isPresented: $isShowingCues) {
            CueListSheet(titles: status?.cueTitles ?? [], current: status?.currentCue) { index in
                model.perform(.jumpToCue(index))
                isShowingCues = false
            }
        }
    }

    private var elapsed: String {
        Duration.seconds(Int(status?.elapsed ?? 0)).formatted(.time(pattern: .minuteSecond))
    }

    private var context: Text {
        guard let status else { return Text("In attesa del Mac") }
        if let left = status.countdownLeft { return Text("Parte tra \(left)") }
        if status.currentLine.isEmpty { return Text("Nessun copione aperto sul Mac") }
        return Text(status.currentLine)
    }

    private var transport: some View {
        VStack(spacing: SbuTheme.space3) {
            HStack(spacing: SbuTheme.space3) {
                Button("Sezione precedente", systemImage: "chevron.left") { model.perform(.previousCue) }
                    .labelStyle(.iconOnly)
                Button(isPlaying ? "Pausa" : "Avvia", systemImage: isPlaying ? "pause.fill" : "play.fill") {
                    model.perform(.togglePlay)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("playPause")
                Button("Sezione successiva", systemImage: "chevron.right") { model.perform(.nextCue) }
                    .labelStyle(.iconOnly)
            }
            HStack(spacing: SbuTheme.space3) {
                Button("Più lento", systemImage: "tortoise") { model.perform(.slower) }
                    .labelStyle(.iconOnly)
                Text(speedText)
                    .accessibilityIdentifier("speed")
                    .font(SbuTheme.body.monospacedDigit())
                    .foregroundStyle(SbuTheme.inkMuted)
                    .frame(maxWidth: .infinity)
                Button("Più veloce", systemImage: "hare") { model.perform(.faster) }
                    .labelStyle(.iconOnly)
            }
            .disabled(status?.isVoice ?? false)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private var speedText: String {
        guard let status else { return "" }
        if status.isVoice { return String(localized: "Segue la voce") }
        return String(localized: "Velocità \(Int(status.speed))")
    }
}

#Preview("Light") {
    NavigationStack { ControlView(model: RemoteModel(), mac: "MacBook di Matteo") }
        .tint(SbuTheme.ink)
}

#Preview("Dark") {
    NavigationStack { ControlView(model: RemoteModel(), mac: "MacBook di Matteo") }
        .tint(SbuTheme.ink)
        .preferredColorScheme(.dark)
}
