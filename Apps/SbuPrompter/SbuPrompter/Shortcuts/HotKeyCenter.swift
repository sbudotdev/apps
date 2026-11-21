import Carbon.HIToolbox

/// Global shortcuts through Carbon's `RegisterEventHotKey`: works in the sandbox and needs
/// no Accessibility permission.
final class HotKeyCenter {
    var onAction: (ShortcutAction) -> Void = { _ in }

    private var references: [EventHotKeyRef] = []
    private var handler: EventHandlerRef?

    func register(_ combos: [ShortcutAction: KeyCombo]) {
        unregisterAll()
        installHandlerIfNeeded()
        for (index, action) in ShortcutAction.allCases.enumerated() {
            guard let combo = combos[action], combo.isValidGlobal else { continue }
            var reference: EventHotKeyRef?
            let id = EventHotKeyID(signature: Self.signature, id: UInt32(index))
            let status = RegisterEventHotKey(combo.keyCode, Self.carbonModifiers(combo.modifiers), id,
                                             GetEventDispatcherTarget(), 0, &reference)
            if status == noErr, let reference { references.append(reference) }
        }
    }

    func unregisterAll() {
        references.forEach { UnregisterEventHotKey($0) }
        references.removeAll()
    }

    fileprivate func fire(_ index: UInt32) {
        let actions = ShortcutAction.allCases
        guard Int(index) < actions.count else { return }
        onAction(actions[Int(index)])
    }

    private func installHandlerIfNeeded() {
        guard handler == nil else { return }
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetEventDispatcherTarget(), hotKeyCallback, 1, &spec,
                            Unmanaged.passUnretained(self).toOpaque(), &handler)
    }

    /// 'SbuP'
    private static let signature: OSType = 0x5362_7550

    private static func carbonModifiers(_ modifiers: KeyCombo.Modifiers) -> UInt32 {
        var result = 0
        if modifiers.contains(.command) { result |= cmdKey }
        if modifiers.contains(.option) { result |= optionKey }
        if modifiers.contains(.control) { result |= controlKey }
        if modifiers.contains(.shift) { result |= shiftKey }
        return UInt32(result)
    }
}

/// Carbon delivers hot keys on the main thread.
private nonisolated func hotKeyCallback(_: EventHandlerCallRef?, event: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus {
    guard let event, let userData else { return OSStatus(eventNotHandledErr) }
    var id = EventHotKeyID()
    let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
                                   nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
    guard status == noErr else { return status }
    let index = id.id
    nonisolated(unsafe) let pointer = userData
    MainActor.assumeIsolated {
        Unmanaged<HotKeyCenter>.fromOpaque(pointer).takeUnretainedValue().fire(index)
    }
    return noErr
}
