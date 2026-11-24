import AppKit
import SwiftUI

/// Places the prompter panel (notch, pill or floating), drives the per-frame tick,
/// pauses on hover and turns trackpad scrolling into manual scrolling.
final class PrompterWindowController: NSObject {
    private let panel = PrompterPanel()
    private let model: AppModel
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    /// Frames ticked so far, for the DEBUG status line.
    private(set) var ticks = 0
    var isOccluded: Bool { !panel.occlusionState.contains(.visible) }
    private var scrollMonitor: Any?
    private var chrome: PrompterChrome = .pill
    private var shownChrome: PrompterChrome?
    private var shownIsEmpty: Bool?

    private static let floatingName = "SbuPrompterFloating"

    init(model: AppModel) {
        self.model = model
        super.init()
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            guard let self, event.window === self.panel else { return event }
            let factor: Double = event.hasPreciseScrollingDeltas ? 1 : 12
            self.model.controller.scrollManually(by: -Double(event.scrollingDeltaY) * factor)
            return nil
        }
        NotificationCenter.default.addObserver(self, selector: #selector(screensChanged),
                                               name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    var isVisible: Bool { panel.isVisible }

    var contentView: NSView? { panel.contentView }

    func show() {
        layout()
        panel.orderFrontRegardless()
        updateTicking()
    }

    func hide() {
        panel.orderOut(nil)
        updateTicking()
    }

    /// Re-reads the settings: size, notch or floating.
    func layout() {
        let settings = model.settings
        let screen = NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main ?? NSScreen.screens[0]
        if settings.layout == .floating {
            panel.configure(floating: true)
            chrome = .floating
            if panel.frameAutosaveName != Self.floatingName {
                panel.setFrame(defaultFloatingFrame(on: screen), display: false)
                panel.setFrameAutosaveName(Self.floatingName)
                panel.setFrameUsingName(Self.floatingName)
            }
        } else {
            panel.setFrameAutosaveName("")
            panel.configure(floating: false)
            let placement = PanelPlacement(screen: Self.describe(screen), width: settings.width, height: settings.height,
                                           forcePill: Self.forcePill)
            chrome = placement.style == .notch ? .notch(height: placement.notchHeight) : .pill
            panel.setFrame(placement.frame, display: true)
        }
        let isEmpty = model.controller.script.words.isEmpty && model.controller.script.cues.isEmpty
        // Only a new frame for a new size: replacing the view would cut a drag on the panel's edge.
        guard panel.contentView == nil || chrome != shownChrome || isEmpty != shownIsEmpty else { return }
        shownChrome = chrome
        shownIsEmpty = isEmpty
        panel.contentView = NSHostingView(rootView: PrompterView(
            controller: model.controller, settings: settings, speech: model.speech, chrome: chrome, isEmpty: isEmpty))
    }

    /// Runs the display link only while the text can move.
    func updateTicking() {
        let shouldTick = panel.isVisible && model.controller.isPlaying
        if shouldTick, displayLink == nil {
            // From the window, not its content view: `layout()` replaces the view while the text scrolls.
            let link = panel.displayLink(target: self, selector: #selector(step))
            link.add(to: .main, forMode: .common)
            displayLink = link
            lastTimestamp = nil
        } else if !shouldTick, let link = displayLink {
            link.invalidate()
            displayLink = nil
            model.controller.isHoverPaused = false
        }
    }

    @objc private func step(_ link: CADisplayLink) {
        ticks += 1
        // Capped so a stalled display (sleep, screen off) doesn't jump the text on wake.
        // Wall clock: the link's own timestamp didn't advance steadily for a panel on macOS 26.
        let now = CACurrentMediaTime()
        let seconds = lastTimestamp.map { min(now - $0, 0.5) } ?? 0
        lastTimestamp = now
        let hovering = panel.frame.contains(NSEvent.mouseLocation)
        if model.controller.isHoverPaused != hovering { model.controller.isHoverPaused = hovering }
        model.controller.tick(seconds)
    }

    @objc private func screensChanged() {
        if panel.isVisible { layout() }
    }

    private func defaultFloatingFrame(on screen: NSScreen) -> NSRect {
        let size = NSSize(width: 520, height: 240)
        let visible = screen.visibleFrame
        return NSRect(x: visible.midX - size.width / 2, y: visible.maxY - size.height - 80, width: size.width, height: size.height)
    }

    private static func describe(_ screen: NSScreen) -> PanelPlacement.Screen {
        var described = PanelPlacement.Screen(
            frame: screen.frame, visibleFrame: screen.visibleFrame, safeAreaTop: screen.safeAreaInsets.top,
            leftAuxiliaryWidth: screen.auxiliaryTopLeftArea?.width, rightAuxiliaryWidth: screen.auxiliaryTopRightArea?.width)
        #if DEBUG
        // `-SbuPrompterSimulateNotch 32` lays the panel out as on a 32 pt notch, for QA on Macs without one.
        let simulated = CGFloat(UserDefaults.standard.double(forKey: "SbuPrompterSimulateNotch"))
        if simulated > 0, described.safeAreaTop == 0 {
            described.safeAreaTop = simulated
            described.leftAuxiliaryWidth = (screen.frame.width - 200) / 2
            described.rightAuxiliaryWidth = (screen.frame.width - 200) / 2
        }
        #endif
        return described
    }

    /// `-SbuPrompterForcePill YES` shows the pill on a Mac with a notch, for screenshots and QA.
    private static var forcePill: Bool { UserDefaults.standard.bool(forKey: "SbuPrompterForcePill") }
}
