// Sbu Bar arranger spike. Throwaway: answers "can we move another app's menu bar item
// to a chosen position, reliably, without the pointer visibly moving, and how fast?".
//
//   BarSpike perms                   permission state, read-only
//   BarSpike list                    menu bar items of other apps, read-only
//   BarSpike move N M                put item N immediately right of item M (indices from `list`)
//   BarSpike measure N M [count]     alternate N right of M / back, `count` attempts (default 20)
//
//   move and measure take `--post hid|app|agent` (default hid): where the synthetic events go.
//   hid   = CGEvent.post(tap: .cghidEventTap), as if from the mouse: moves the real pointer.
//   app   = CGEvent.postToPid(item's owner): no pointer motion, but WindowServer hit-testing is skipped.
//   agent = CGEvent.postToPid(MenuBarAgent): same, aimed at the process hosting the menu extras on macOS 26+.
//
// Public API only: Accessibility (AXUIElement, kAXExtrasMenuBarAttribute), Quartz Event
// Services (CGEvent, CGWarpMouseCursorPosition), Quartz Window Services (CGWindowList).

import AppKit
import ApplicationServices

struct Item {
    let app: String
    let pid: pid_t
    let label: String
    let frame: CGRect
    let element: AXUIElement
}

// MARK: - Permissions

func permissionReport() -> String {
    """
    binary:              \(CommandLine.arguments[0])
    accessibility:       \(AXIsProcessTrusted())
    post events:         \(CGPreflightPostEventAccess())
    screen recording:    \(CGPreflightScreenCaptureAccess())
    """
}

// MARK: - Reading

func axValue<T>(_ element: AXUIElement, _ attribute: String, as _: T.Type) -> T? {
    var raw: CFTypeRef?
    guard AXUIElementCopyAttributeValue(element, attribute as CFString, &raw) == .success else { return nil }
    return raw as? T
}

func frame(of element: AXUIElement) -> CGRect? {
    guard let pos = axValue(element, kAXPositionAttribute, as: AXValue.self),
          let size = axValue(element, kAXSizeAttribute, as: AXValue.self) else { return nil }
    var point = CGPoint.zero, extent = CGSize.zero
    AXValueGetValue(pos, .cgPoint, &point)
    AXValueGetValue(size, .cgSize, &extent)
    return CGRect(origin: point, size: extent)
}

/// Every app's status items, read through the app's AXExtrasMenuBar, sorted left to right.
func readItems() -> [Item] {
    var items: [Item] = []
    for app in NSWorkspace.shared.runningApplications where app.processIdentifier != getpid() {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(appElement, 0.25) // hung apps must not stall the scan
        guard let bar = axValue(appElement, kAXExtrasMenuBarAttribute, as: AXUIElement.self),
              let children = axValue(bar, kAXChildrenAttribute, as: [AXUIElement].self) else { continue }
        // macOS 27: MenuBarAgent wraps each system extra (Wi-Fi, Control Centre, Clock) in an
        // AXGroup/AXHostingView; the AXMenuBarItem is one level down.
        let flat = children.flatMap { child in
            axValue(child, kAXRoleAttribute, as: String.self) == kAXGroupRole
                ? axValue(child, kAXChildrenAttribute, as: [AXUIElement].self) ?? [] : [child]
        }
        for child in flat {
            guard let rect = frame(of: child) else { continue }
            let label = [kAXTitleAttribute, kAXDescriptionAttribute, kAXIdentifierAttribute, kAXHelpAttribute]
                .lazy.compactMap { axValue(child, $0, as: String.self) }.first { !$0.isEmpty } ?? "?"
            items.append(Item(app: app.localizedName ?? app.bundleIdentifier ?? "pid \(app.processIdentifier)",
                              pid: app.processIdentifier, label: label, frame: rect, element: child))
        }
    }
    return items.sorted { $0.frame.minX < $1.frame.minX }
}

/// Status-item windows as WindowServer sees them. Works without Accessibility; window
/// titles of other apps are only filled in with Screen Recording.
func statusWindows() -> [(owner: String, name: String, bounds: CGRect)] {
    let info = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] ?? []
    let statusLevel = Int(CGWindowLevelForKey(.statusWindow))
    return info.compactMap { window in
        guard window[kCGWindowLayer as String] as? Int == statusLevel,
              let dict = window[kCGWindowBounds as String] as! CFDictionary?,
              let bounds = CGRect(dictionaryRepresentation: dict) else { return nil }
        return (window[kCGWindowOwnerName as String] as? String ?? "?",
                window[kCGWindowName as String] as? String ?? "", bounds)
    }.sorted { $0.bounds.minX < $1.bounds.minX }
}

func printList() {
    print(permissionReport())
    print("\nscreens:")
    for screen in NSScreen.screens {
        let notch = screen.safeAreaInsets.top > 0
        print("  \(screen.localizedName)  frame \(screen.frame)  notch \(notch)"
              + (notch ? "  left of notch ends at x \(screen.auxiliaryTopLeftArea?.maxX ?? 0), right starts at x \(screen.auxiliaryTopRightArea?.minX ?? 0)" : ""))
    }
    print("\nstatus windows (CGWindowList, layer \(CGWindowLevelForKey(.statusWindow))):")
    let windows = statusWindows()
    if windows.isEmpty { print("  none: status items have no windows of their own here") }
    for w in windows {
        print(String(format: "  x %7.1f  w %5.1f  %@  %@", w.bounds.minX, w.bounds.width, w.owner, w.name))
    }
    guard AXIsProcessTrusted() else {
        print("\nAccessibility not granted: AX item list skipped.")
        return
    }
    print("\nitems (Accessibility, AXExtrasMenuBar):")
    for (index, item) in readItems().enumerated() {
        print(String(format: "  %2d  x %7.1f  y %5.1f  w %5.1f  %@ — %@",
                     index, item.frame.minX, item.frame.minY, item.frame.width, item.app, item.label))
    }
}

// MARK: - Moving

enum Route: String { case hid, app, agent }
nonisolated(unsafe) var route = Route.hid // single-threaded CLI
nonisolated(unsafe) var routePID: pid_t = 0

func post(_ type: CGEventType, at point: CGPoint, flags: CGEventFlags = .maskCommand) {
    guard let event = CGEvent(mouseEventSource: CGEventSource(stateID: .hidSystemState),
                              mouseType: type, mouseCursorPosition: point, mouseButton: .left) else { return }
    event.flags = flags
    if route == .hid { event.post(tap: .cghidEventTap) } else { event.postToPid(routePID) }
}

func pause(_ ms: UInt32) { usleep(ms * 1000) }

/// Timing knobs, so Matteo can retry a failed drag slower without a rebuild.
func knob(_ name: String, _ fallback: UInt32) -> UInt32 {
    ProcessInfo.processInfo.environment[name].flatMap(UInt32.init) ?? fallback
}

func current(_ item: Item) -> CGRect? { frame(of: item.element) }

/// True when `moving` sits immediately right of `anchor` (no other item between them).
func isRight(of anchor: Item, _ moving: Item) -> Bool {
    guard let a = current(anchor), let m = current(moving), m.minX > a.minX else { return false }
    return !readItems().contains { $0.frame.minX > a.minX + 0.5 && $0.frame.minX < m.minX - 0.5 }
}

struct MoveResult { let ok: Bool; let ms: Double; let pointerDrift: CGFloat; let pointerRestored: Bool }

/// ⌘-drag `moving` so it lands immediately right of `anchor`: the same gesture a person uses,
/// synthesised with Quartz events, then the pointer is warped back to where it was.
func move(_ moving: Item, rightOf anchor: Item, hideCursor: Bool = true) -> MoveResult {
    let start = Date()
    routePID = route == .agent
        ? NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.MenuBarAgent").first?.processIdentifier ?? moving.pid
        : moving.pid
    let saved = CGEvent(source: nil)?.location ?? .zero
    guard let from = current(moving), let to = current(anchor) else {
        return MoveResult(ok: false, ms: 0, pointerDrift: 0, pointerRestored: true)
    }
    // Dropping past the anchor's midpoint from the left, or on the next item's left half from
    // the right, both end with `moving` right of `anchor`.
    let dropX = from.minX < to.minX ? to.maxX - 2 : to.maxX + 2
    let source = CGPoint(x: from.midX, y: from.midY)
    let target = CGPoint(x: dropX, y: from.midY)

    if hideCursor { CGDisplayHideCursor(CGMainDisplayID()) }
    var maxDrift: CGFloat = 0
    post(.leftMouseDown, at: source)
    pause(knob("BAR_SPIKE_HOLD_MS", 30))
    let steps = 6
    for step in 1...steps {
        let t = CGFloat(step) / CGFloat(steps)
        post(.leftMouseDragged, at: CGPoint(x: source.x + (target.x - source.x) * t, y: source.y))
        pause(knob("BAR_SPIKE_STEP_MS", 15))
        if let now = CGEvent(source: nil)?.location { maxDrift = max(maxDrift, hypot(now.x - saved.x, now.y - saved.y)) }
    }
    post(.leftMouseUp, at: target)
    pause(20)
    CGWarpMouseCursorPosition(saved)
    CGAssociateMouseAndMouseCursorPosition(1) // warping detaches mouse and cursor briefly; reattach
    if hideCursor { CGDisplayShowCursor(CGMainDisplayID()) }

    let restored = (CGEvent(source: nil)?.location).map { hypot($0.x - saved.x, $0.y - saved.y) < 1 } ?? false
    var ok = false
    let deadline = Date().addingTimeInterval(1)
    while Date() < deadline {
        if isRight(of: anchor, moving) { ok = true; break }
        pause(20)
    }
    return MoveResult(ok: ok, ms: Date().timeIntervalSince(start) * 1000, pointerDrift: maxDrift, pointerRestored: restored)
}

func requireMovePermissions() {
    // Moving posts real mouse events: only on purpose, never from a stray command.
    guard ProcessInfo.processInfo.environment["BAR_SPIKE_MOVE"] == "1" else {
        print("move and measure post real mouse events. Run with BAR_SPIKE_MOVE=1 to confirm.")
        exit(3)
    }
    guard AXIsProcessTrusted(), CGPreflightPostEventAccess() else {
        print(permissionReport())
        print("Grant Accessibility to the binary above, then run again.")
        exit(2)
    }
}

func pick(_ args: ArraySlice<String>) -> (Item, Item) {
    let items = readItems()
    guard args.count >= 2, let n = Int(args[args.startIndex]), let m = Int(args[args.startIndex + 1]),
          items.indices.contains(n), items.indices.contains(m), n != m else {
        print("usage: BarSpike move|measure N M   (indices from `BarSpike list`, N != M)")
        exit(1)
    }
    return (items[n], items[m])
}

// MARK: - Main

var argv = Array(CommandLine.arguments.dropFirst())
if let i = argv.firstIndex(of: "--post") {
    guard argv.indices.contains(i + 1), let r = Route(rawValue: argv[i + 1]) else {
        print("--post takes hid, app or agent"); exit(1)
    }
    route = r
    argv.removeSubrange(i...(i + 1))
}
let args = argv[...]
switch args.first {
case "perms":
    print(permissionReport())
case "list", nil:
    printList()
case "move":
    requireMovePermissions()
    let (moving, anchor) = pick(args.dropFirst())
    let r = move(moving, rightOf: anchor)
    print(String(format: "%@  %.0f ms  pointer drift %.0f pt  restored %@",
                 r.ok ? "OK" : "FAILED", r.ms, r.pointerDrift, r.pointerRestored ? "yes" : "no"))
case "measure":
    requireMovePermissions()
    let (moving, anchor) = pick(args.dropFirst())
    let count = args.dropFirst(3).first.flatMap(Int.init) ?? 20
    // Remember what was right of `moving` so every second attempt can put it back.
    let before = readItems()
    let home = before.last { $0.frame.minX < (current(moving)?.minX ?? 0) - 0.5 }
    guard let home else {
        print("item N is the leftmost item; pick another N")
        exit(1)
    }
    print("attempt  target              result  ms     drift  restored")
    var results: [MoveResult] = []
    for attempt in 1...count {
        let goesOut = attempt % 2 == 1
        let r = move(moving, rightOf: goesOut ? anchor : home)
        results.append(r)
        print(String(format: "%7d  %-18@  %-6@  %5.0f  %5.0f  %@", attempt,
                     goesOut ? "right of M" : "back home", r.ok ? "OK" : "FAIL", r.ms, r.pointerDrift,
                     r.pointerRestored ? "yes" : "no"))
        pause(300)
    }
    let ok = results.filter(\.ok)
    let mean = ok.isEmpty ? 0 : ok.map(\.ms).reduce(0, +) / Double(ok.count)
    let worst = results.map(\.ms).max() ?? 0
    print(String(format: "\nsuccess %d/%d  mean %.0f ms (successful)  worst %.0f ms  max pointer drift %.0f pt  all restored %@",
                 ok.count, results.count, mean, worst, results.map(\.pointerDrift).max() ?? 0,
                 results.allSatisfy(\.pointerRestored) ? "yes" : "no"))
default:
    print("usage: BarSpike perms | list | move N M [--post hid|app|agent] | measure N M [count] [--post hid|app|agent]")
    exit(1)
}
