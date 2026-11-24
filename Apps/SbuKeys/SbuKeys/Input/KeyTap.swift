import CoreGraphics
import Foundation

/// Listens to key presses in every app, read-only, through a Core Graphics event tap.
///
/// Needs Input Monitoring (Privacy & Security). Only the key code and whether the key went down
/// or up reach `onKey`: the characters typed are never read. macOS sends nothing while a password
/// field has Secure Input on, so password keys make no sound.
final class KeyTap {
    /// Called on the main thread with the virtual key code and `true` for a press.
    var onKey: (_ keyCode: Int, _ isDown: Bool) -> Void = { _, _ in }

    /// The tap the C callback reports to; there is one per app.
    fileprivate static weak var active: KeyTap?

    private var port: CFMachPort?
    private var source: CFRunLoopSource?

    var isRunning: Bool { port != nil }

    /// Whether Input Monitoring is granted, without asking.
    static var hasAccess: Bool { CGPreflightListenEventAccess() }

    /// Shows the system prompt the first time; later it only answers.
    @discardableResult
    static func requestAccess() -> Bool { CGRequestListenEventAccess() }

    /// Starts listening; returns `false` while Input Monitoring is not granted.
    @discardableResult
    func start() -> Bool {
        guard port == nil else { return true }
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue) | CGEventMask(1 << CGEventType.keyUp.rawValue)
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: keyTapCallback,
            userInfo: nil
        ) else { return false }
        let source = CFMachPortCreateRunLoopSource(nil, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        self.port = port
        self.source = source
        Self.active = self
        return true
    }

    func stop() {
        guard let port else { return }
        CGEvent.tapEnable(tap: port, enable: false)
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        self.port = nil
        source = nil
    }

    fileprivate func handle(_ type: CGEventType, keyCode: Int, isRepeat: Bool) {
        switch type {
        case .keyDown, .keyUp:
            // A held key repeats keyDown: one sound per press, like a real switch.
            guard !isRepeat else { return }
            onKey(keyCode, type == .keyDown)
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            if let port { CGEvent.tapEnable(tap: port, enable: true) }
        default:
            break
        }
    }
}

/// The C callback: the run loop source is on the main run loop, so this runs on the main thread.
nonisolated private func keyTapCallback(
    proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    // Only plain values cross into the main actor, never the event itself.
    let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
    let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
    MainActor.assumeIsolated {
        KeyTap.active?.handle(type, keyCode: keyCode, isRepeat: isRepeat)
    }
    return Unmanaged.passUnretained(event)
}
