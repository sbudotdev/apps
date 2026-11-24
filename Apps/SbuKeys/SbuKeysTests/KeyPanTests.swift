@testable import SbuKeys
import Testing

struct KeyPanTests {
    @Test func outermostKeysStopAtTheWidth() {
        #expect(KeyPan.pan(forKeyCode: 50) == -KeyPan.width) // ` top left
        #expect(KeyPan.pan(forKeyCode: 42) == KeyPan.width) // Backslash, end of the Q row
    }

    @Test(arguments: [(0, 37), (12, 35), (6, 44), (18, 29)])
    func leftHandIsLeftOfRightHand(left: Int, right: Int) {
        #expect(KeyPan.pan(forKeyCode: left) < 0)
        #expect(KeyPan.pan(forKeyCode: right) > 0)
    }

    @Test(arguments: [49, 123, 126, 122, 82, 999])
    func spaceAndKeysOffTheMainBlockStayNearTheCentre(keyCode: Int) {
        #expect(abs(KeyPan.pan(forKeyCode: keyCode)) < 0.1)
    }

    @Test func everyKeyIsWithinTheWidth() {
        for code in 0..<128 {
            #expect(abs(KeyPan.pan(forKeyCode: code)) <= KeyPan.width)
        }
    }
}
