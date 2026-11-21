import AppKit
import Observation
import SwiftData

/// Owns the prompter, its window, the voice, the shortcuts and the library storage.
@Observable
final class AppModel {
    let controller = PrompterController()
    let settings = PrompterSettings()
    let speech = SpeechFollower()
    let container: ModelContainer
    private(set) var activeScriptID: UUID?
    private(set) var isPrompterVisible = false

    @ObservationIgnored private let hotKeys = HotKeyCenter()
    @ObservationIgnored private var window: PrompterWindowController?

    init() {
        do {
            container = try ModelContainer(for: Script.self)
        } catch {
            fatalError("Library store failed to open: \(error)")
        }
        activeScriptID = UserDefaults.standard.string(forKey: "activeScript").flatMap(UUID.init)
        applySettings()
        settings.onChange = { [weak self] in self?.applySettings() }
        speech.onWords = { [weak self] words in self?.controller.heard(words) }
        // Play and pause also come from the panel button and the end of the text, not only from `perform`.
        controller.onPlayingChange = { [weak self] in
            self?.window?.updateTicking()
            self?.syncSpeech()
        }
        hotKeys.onAction = { [weak self] action in self?.perform(action.command) }
        hotKeys.register(settings.shortcuts)

        let window = PrompterWindowController(model: self)
        self.window = window
        insertWelcomeScriptIfEmpty()
        if let script = activeScript { controller.load(script.body) }
        window.show()
        isPrompterVisible = true
        #if DEBUG
        DebugSnapshots.runIfRequested(model: self, prompter: window.contentView)
        DebugSnapshots.listenForSignal(model: self, window: window)
        #endif
    }

    var activeScript: Script? {
        guard let activeScriptID else { return nil }
        let descriptor = FetchDescriptor<Script>(predicate: #Predicate { $0.id == activeScriptID })
        return try? container.mainContext.fetch(descriptor).first
    }

    func perform(_ command: PrompterCommand) {
        if command == .toggleVisibility {
            setPrompterVisible(!isPrompterVisible)
            return
        }
        controller.perform(command)
        if settings.speed != controller.speed { settings.speed = controller.speed }
        window?.updateTicking()
        syncSpeech()
    }

    /// Loads `script` into the prompter, from the top, and shows it.
    func read(_ script: Script) {
        activeScriptID = script.id
        UserDefaults.standard.set(script.id.uuidString, forKey: "activeScript")
        controller.pause()
        controller.load(script.body)
        controller.perform(.rewind)
        relayout()
        setPrompterVisible(true)
        syncSpeech()
    }

    /// The active script was edited in the library.
    func scriptChanged(_ script: Script) {
        guard script.id == activeScriptID else { return }
        controller.load(script.body)
        relayout()
    }

    func scriptDeleted(_ id: UUID) {
        guard id == activeScriptID else { return }
        activeScriptID = nil
        UserDefaults.standard.removeObject(forKey: "activeScript")
        controller.pause()
        controller.load("")
        relayout()
        syncSpeech()
    }

    func setPrompterVisible(_ visible: Bool) {
        isPrompterVisible = visible
        if visible {
            window?.show()
        } else {
            controller.pause()
            window?.hide()
            syncSpeech()
        }
    }

    func relayout() {
        if isPrompterVisible { window?.layout() }
    }

    /// While recording a new shortcut the old ones must not fire.
    func suspendShortcuts(_ suspended: Bool) {
        if suspended { hotKeys.unregisterAll() } else { hotKeys.register(settings.shortcuts) }
    }

    private func applySettings() {
        controller.mode = settings.mode
        controller.countdownSeconds = settings.countdown
        controller.speed = settings.speed
        syncSpeech()
    }

    private func syncSpeech() {
        let shouldListen = settings.mode == .voice && controller.isPlaying && isPrompterVisible
        if shouldListen, !speech.isListening {
            Task { await speech.start(localeIdentifier: settings.voiceLocale) }
        } else if !shouldListen, speech.isListening {
            speech.stop()
        }
    }

    private func insertWelcomeScriptIfEmpty() {
        let context = container.mainContext
        guard (try? context.fetchCount(FetchDescriptor<Script>())) == 0 else { return }
        let script = Script(title: String(localized: "Benvenuto"), body: String(localized: "welcome.script"))
        context.insert(script)
        try? context.save()
        activeScriptID = script.id
        UserDefaults.standard.set(script.id.uuidString, forKey: "activeScript")
    }
}
