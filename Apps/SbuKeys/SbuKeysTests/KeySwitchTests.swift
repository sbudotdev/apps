@testable import SbuKeys
import Foundation
import Testing

struct KeySwitchTests {
    @Test func soundNameJoinsSwitchKindAndPhase() {
        #expect(KeySwitch.clicky.soundName(for: .space, isDown: true) == "clicky-space-down")
        #expect(KeySwitch.linear.soundName(for: .key, isDown: false) == "linear-key-up")
    }

    /// Every sample the player asks for ships in the app bundle.
    @Test(arguments: KeySwitch.allCases)
    func everySampleIsInTheBundle(keySwitch: KeySwitch) throws {
        let bundle = try #require(Bundle(identifier: "dev.sbu.keys"))
        for kind in KeyKind.allCases {
            for isDown in [true, false] {
                let name = keySwitch.soundName(for: kind, isDown: isDown)
                #expect(bundle.url(forResource: name, withExtension: "caf") != nil, "missing \(name)")
            }
        }
    }
}
