import CoreGraphics
import Testing
@testable import SbuPrompter

struct PrompterChromeTests {
    /// A 460×160 panel hanging from a 200×32 notch at the top of a 1000×800 screen (y up).
    let frame = CGRect(x: 270, y: 640, width: 460, height: 160)
    let notch = PrompterChrome.notch(height: 32, width: 200)

    @Test(arguments: [
        (CGPoint(x: 500, y: 790), true),   // in the notch column
        (CGPoint(x: 300, y: 790), false),  // menu bar row, left of the notch: the menu bar's
        (CGPoint(x: 700, y: 790), false),  // and right of it
        (CGPoint(x: 300, y: 700), true),   // below the menu bar, full width
        (CGPoint(x: 500, y: 600), false),  // under the panel
    ])
    func notchPanelLeavesTheMenuBarBesideTheNotch(point: CGPoint, expected: Bool) {
        #expect(notch.contains(point, panelFrame: frame) == expected)
    }

    @Test func pillAndFloatingAreTheirWholeFrame() {
        #expect(PrompterChrome.pill.contains(CGPoint(x: 300, y: 790), panelFrame: frame))
        #expect(PrompterChrome.floating.contains(CGPoint(x: 729, y: 641), panelFrame: frame))
    }
}
