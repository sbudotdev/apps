#if DEBUG
import AppKit
import SwiftUI

/// `-SbuPrompterSnapshots YES` renders the prompter, the library and the settings into PNGs
/// in the app's temporary folder, then quits. For QA screenshots on Macs where the agent
/// has no Screen Recording permission (the prompter is hidden from captures anyway).
enum DebugSnapshots {
    static var isRequested: Bool { UserDefaults.standard.bool(forKey: "SbuPrompterSnapshots") }

    /// `kill -USR1 <pid>` saves the live prompter as `live-<n>.png` and prints its status, to check
    /// scrolling, hover pause and voice following on a running app.
    static func listenForSignal(model: AppModel, window: PrompterWindowController) {
        signal(SIGUSR1, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
        var count = 0
        source.setEventHandler {
            MainActor.assumeIsolated {
                count += 1
                let folder = URL(filePath: NSTemporaryDirectory()).appending(path: "snapshots")
                try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                save(window.contentView, folder.appending(path: "live-\(count).png"))
                let status = model.controller.status
                let line = "LIVE \(count) offset=\(Int(model.controller.engine.offset))/\(Int(model.controller.engine.maxOffset)) speed=\(model.controller.speed) playing=\(status.isPlaying) hover=\(model.controller.isHoverPaused) words=\(model.controller.readWordCount) cue=\(status.currentCue.map(String.init) ?? "-") listening=\(model.speech.isListening) problem=\(String(describing: model.speech.problem)) level=\(model.speech.level) ticks=\(window.ticks) occluded=\(window.isOccluded)\n"
                FileHandle.standardError.write(Data(line.utf8))
            }
        }
        source.resume()
        signalSource = source
    }

    private static var signalSource: (any DispatchSourceSignal)?

    static func runIfRequested(model: AppModel, prompter: NSView?) {
        guard isRequested else { return }
        let folder = URL(filePath: NSTemporaryDirectory()).appending(path: "snapshots")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let suffix = UserDefaults.standard.string(forKey: "SbuPrompterSnapshotSuffix") ?? ""

        Task {
            // Out of the SwiftUI update that creates the app model.
            try? await Task.sleep(for: .seconds(1))
            let settings = window(SettingsView().environment(model), size: NSSize(width: 540, height: 360), title: String(localized: "Impostazioni"))
            try? await Task.sleep(for: .seconds(2))
            save(prompter, folder.appending(path: "prompter\(suffix).png"))
            // The library is the real scene, opened at launch by `defaultLaunchBehavior` in snapshot mode.
            let library = NSApp.windows.first { $0.identifier?.rawValue.contains(LibraryView.windowID) == true }
            save(library?.contentView?.superview, folder.appending(path: "library\(suffix).png"))
            save(settings.contentView?.superview, folder.appending(path: "settings\(suffix).png"))
            FileHandle.standardError.write(Data("SNAPSHOTS \(folder.path(percentEncoded: false))\n".utf8))
            NSApp.terminate(nil)
        }
    }

    private static func window(_ view: some View, size: NSSize, title: String) -> NSWindow {
        let window = NSWindow(contentRect: NSRect(origin: NSPoint(x: 200, y: 200), size: size),
                              styleMask: [.titled, .closable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        window.title = title
        window.contentView = NSHostingView(rootView: view)
        window.setContentSize(size)
        window.isReleasedWhenClosed = false
        window.orderFrontRegardless()
        return window
    }

    private static func save(_ view: NSView?, _ url: URL) {
        guard let view, let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else {
            FileHandle.standardError.write(Data("SNAPSHOT no view for \(url.lastPathComponent)\n".utf8))
            return
        }
        view.cacheDisplay(in: view.bounds, to: rep)
        do {
            try rep.representation(using: .png, properties: [:])?.write(to: url)
        } catch {
            FileHandle.standardError.write(Data("SNAPSHOT \(error)\n".utf8))
        }
    }
}
#endif
