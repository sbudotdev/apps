@testable import SbuKeys
import Testing

struct KeyKindTests {
    @Test(arguments: [
        (49, KeyKind.space),
        (36, .enter), (76, .enter), (51, .enter), (117, .enter), (48, .enter),
        (0, .key), (12, .key), (122, .key), (126, .key),
    ])
    func kindOfKeyCode(keyCode: Int, expected: KeyKind) {
        #expect(KeyKind(keyCode: keyCode) == expected)
    }
}
