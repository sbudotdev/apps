import SbuKit
import SwiftUI

/// The remote inside the standard Sbu shell: the empty screen until a Mac joins, then the code,
/// then the controls.
struct RootView: View {
    let model: RemoteModel
    @State private var link: MacLink?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        SbuAppShell("Sbu Prompter", slug: "prompter", accent: .prompter, appIcon: Image(.appIconArtwork)) {
            switch model.phase {
            case .searching, .connecting, .outdated:
                NoMacView(model: model)
            case .needsCode(let mac, let wrong):
                PairingView(mac: mac, wrong: wrong, paused: model.isPairingPaused,
                            chooseAnother: model.macs.count > 1 ? ChooseAnotherMacButton(model: model) : nil) {
                    model.enter(code: $0)
                }
                    // A fresh view, so an empty field, after every wrong code.
                    .id(model.wrongCodes)
            case .connected(let mac):
                ControlView(model: model, mac: mac)
            }
        } settings: {
            MacSection(model: model)
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            guard model.sceneChanged(to: phase), !isOffline else { return }
            if link == nil { link = MacLink(model: model) }
            link?.restart()
        }
        .onChange(of: model.keepsScreenOn, initial: true) { _, keepsOn in
            UIApplication.shared.isIdleTimerDisabled = keepsOn
        }
    }

    /// Previews, and the UI test of the empty screen, run without the network.
    private var isOffline: Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || environment["SBU_PROMPTER_OFFLINE"] == "1"
    }
}

#Preview("Light") {
    RootView(model: RemoteModel())
}

#Preview("Dark") {
    RootView(model: RemoteModel())
        .preferredColorScheme(.dark)
}
