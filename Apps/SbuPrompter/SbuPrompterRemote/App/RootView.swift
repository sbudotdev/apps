import SbuKit
import SwiftUI

/// The remote inside the standard Sbu shell: the empty screen until a Mac joins, then the code,
/// then the controls.
struct RootView: View {
    let model: RemoteModel
    @State private var link: MacLink?
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        SbuAppShell("Sbu Prompter", slug: "prompter", accent: .prompter, appIcon: Image(systemName: "text.aligncenter")) {
            switch model.phase {
            case .searching, .connecting, .outdated:
                NoMacView(model: model)
            case .needsCode(let mac, let wrong):
                PairingView(mac: mac, wrong: wrong) { model.enter(code: $0) }
            case .connected(let mac):
                ControlView(model: model, mac: mac)
            }
        } settings: {
            MacSection(model: model)
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            // iOS drops the session in the background: look again when the app comes back.
            guard phase == .active, !isPreview else { return }
            if link == nil { link = MacLink(model: model) }
            link?.restart()
        }
    }

    private var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}

#Preview("Light") {
    RootView(model: RemoteModel())
}

#Preview("Dark") {
    RootView(model: RemoteModel())
        .preferredColorScheme(.dark)
}
