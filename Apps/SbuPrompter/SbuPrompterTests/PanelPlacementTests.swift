import CoreGraphics
import Testing
@testable import SbuPrompter

struct PanelPlacementTests {
    /// A 14" MacBook Pro: 1512×982 points, 32 pt notch about 200 pt wide.
    let notched = PanelPlacement.Screen(
        frame: CGRect(x: 0, y: 0, width: 1512, height: 982),
        visibleFrame: CGRect(x: 0, y: 0, width: 1512, height: 950),
        safeAreaTop: 32, leftAuxiliaryWidth: 656, rightAuxiliaryWidth: 656)

    let plain = PanelPlacement.Screen(
        frame: CGRect(x: 1512, y: 0, width: 1920, height: 1080),
        visibleFrame: CGRect(x: 1512, y: 0, width: 1920, height: 1055),
        safeAreaTop: 0, leftAuxiliaryWidth: nil, rightAuxiliaryWidth: nil)

    @Test func notchedScreenHangsFromTheTopEdge() {
        let placement = PanelPlacement(screen: notched, width: 420, height: 140, forcePill: false)
        #expect(placement.style == .notch)
        #expect(placement.frame == CGRect(x: 546, y: 842, width: 420, height: 140))
        #expect(placement.notchHeight == 32)
        #expect(placement.notchWidth == 200)
    }

    @Test func panelIsNeverNarrowerThanTheNotch() {
        let placement = PanelPlacement(screen: notched, width: 100, height: 140, forcePill: false)
        #expect(placement.frame.width == 200)
    }

    @Test func screenWithoutNotchGetsAPillUnderTheMenuBar() {
        let placement = PanelPlacement(screen: plain, width: 420, height: 140, forcePill: false)
        #expect(placement.style == .pill)
        #expect(placement.frame == CGRect(x: 1512 + 750, y: 1055 - 140 - PanelPlacement.pillGap, width: 420, height: 140))
        #expect(placement.notchHeight == 0)
    }

    @Test func pillCanBeForcedOnANotchedScreen() {
        let placement = PanelPlacement(screen: notched, width: 420, height: 140, forcePill: true)
        #expect(placement.style == .pill)
    }

    @Test func sizeIsClampedToTheScreen() {
        let placement = PanelPlacement(screen: plain, width: 5000, height: 5000, forcePill: false)
        #expect(placement.frame.width <= plain.frame.width)
        #expect(placement.frame.height <= plain.visibleFrame.height)
    }
}
