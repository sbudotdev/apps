import AppKit

/// The prompter window: borderless, never takes focus from the app you are using,
/// on every Space and over full-screen apps, and left out of screen sharing and screenshots.
final class PrompterPanel: NSPanel {
    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        // Spec point 3: invisible in screen sharing, recordings and screenshots.
        sharingType = .none
        #if DEBUG
        // `-SbuPrompterAllowCapture YES` makes the prompter visible to screenshots, only to take the App Store ones.
        if UserDefaults.standard.bool(forKey: "SbuPrompterAllowCapture") { sharingType = .readOnly }
        #endif
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        setAccessibilityLabel(String(localized: "Prompter"))
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    /// Hanging from the notch (or as a pill) it sits above the menu bar; floating, above normal windows.
    func configure(floating: Bool) {
        level = floating ? .floating : .statusBar
        isMovableByWindowBackground = floating
        if floating {
            styleMask.insert(.resizable)
        } else {
            styleMask.remove(.resizable)
        }
    }
}
