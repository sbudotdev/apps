import AppKit
import ApplicationServices

/// Reads every running app's status items through public Accessibility
/// (`AXExtrasMenuBar`). Needs the Accessibility permission; without it returns no items.
nonisolated struct SystemMenuBarReader: MenuBarReading {
    @concurrent func items() async -> [MenuBarItem] {
        guard AXIsProcessTrusted() else { return [] }
        var result: [MenuBarItem] = []
        for app in NSWorkspace.shared.runningApplications where app.processIdentifier != getpid() {
            guard let bundleID = app.bundleIdentifier else { continue }
            result += Self.items(of: app.processIdentifier, bundleID: bundleID)
        }
        return result
    }

    /// Stable names for one app's items, left to right: the AX identifier, else `Item-<index>`.
    /// A name already used gets `-<index>` (then `-<index>-2`, ...) until it is unused.
    static func names(identifiers: [String?]) -> [String] {
        var seen: Set<String> = []
        return identifiers.indices.map { index in
            let base = identifiers[index].flatMap { $0.isEmpty ? nil : $0 } ?? "Item-\(index)"
            var name = base
            var attempt = 1
            while seen.contains(name) {
                name = attempt == 1 ? "\(base)-\(index)" : "\(base)-\(index)-\(attempt)"
                attempt += 1
            }
            seen.insert(name)
            return name
        }
    }

    private static func items(of pid: pid_t, bundleID: String) -> [MenuBarItem] {
        // A hung app must not stall the scan: the system-wide timeout covers every element we query.
        AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), 0.25)
        let appElement = AXUIElementCreateApplication(pid)
        guard let bar = value(appElement, kAXExtrasMenuBarAttribute, as: AXUIElement.self),
              let children = value(bar, kAXChildrenAttribute, as: [AXUIElement].self) else { return [] }
        // MenuBarAgent hosts each system extra in a group; the item is one level down.
        let elements = children.flatMap { child in
            value(child, kAXRoleAttribute, as: String.self) == kAXGroupRole
                ? value(child, kAXChildrenAttribute, as: [AXUIElement].self) ?? [] : [child]
        }
        let positioned = elements.compactMap { element in frame(of: element).map { (element, $0) } }
            .sorted { $0.1.minX < $1.1.minX }
        let identifiers = positioned.map { value($0.0, kAXIdentifierAttribute, as: String.self) }
        let descriptions = positioned.map { value($0.0, kAXDescriptionAttribute, as: String.self) }
        let titles = positioned.map { value($0.0, kAXTitleAttribute, as: String.self) }
        let names = names(identifiers: identifiers)
        return positioned.indices.map { i in
            MenuBarItem(id: ItemID(bundleID: bundleID, name: names[i]),
                        title: [descriptions[i], titles[i]].lazy.compactMap { $0 }.first { !$0.isEmpty } ?? names[i],
                        frame: positioned[i].1)
        }
    }

    private static func value<T>(_ element: AXUIElement, _ attribute: String, as _: T.Type) -> T? {
        var raw: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &raw) == .success else { return nil }
        return raw as? T
    }

    private static func frame(of element: AXUIElement) -> CGRect? {
        guard let pos = value(element, kAXPositionAttribute, as: AXValue.self),
              let size = value(element, kAXSizeAttribute, as: AXValue.self) else { return nil }
        var point = CGPoint.zero, extent = CGSize.zero
        AXValueGetValue(pos, .cgPoint, &point)
        AXValueGetValue(size, .cgSize, &extent)
        return CGRect(origin: point, size: extent)
    }
}
