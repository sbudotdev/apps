import Foundation
import Testing
@testable import SbuPrompter

struct RemoteCodecTests {
    nonisolated static let status = PrompterStatus(isPlaying: true, speed: 40, isVoice: false, cueTitles: ["Apertura", nil],
                                       currentCue: 1, currentLine: "Ciao a tutti", elapsed: 12.5, countdownLeft: nil)

    @Test(arguments: [
        RemoteMessage.pair(code: "0427"), .resume(token: "abc"), .paired(token: "abc"), .pairingRequired,
        .command(.togglePlay), .command(.jumpToCue(3)), .command(.setSpeed(55)), .status(status),
    ])
    func messagesRoundTrip(_ message: RemoteMessage) throws {
        let data = try RemoteCodec.encode(message)
        #expect(try RemoteCodec.decode(data) == message)
    }

    @Test func encodedMessagesCarryTheVersion() throws {
        let data = try RemoteCodec.encode(.pairingRequired)
        let object = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["version"] as? Int == RemoteCodec.version)
    }

    @Test func unknownVersionIsRejected() throws {
        let data = Data(#"{"version":99,"message":{"pairingRequired":{}}}"#.utf8)
        #expect(throws: RemoteCodec.Failure.unsupportedVersion(99)) {
            try RemoteCodec.decode(data)
        }
    }

    @Test func unknownVersionIsRejectedEvenWithAnUnknownMessage() throws {
        let data = Data(#"{"version":2,"message":{"hologram":{"x":1}}}"#.utf8)
        #expect(throws: RemoteCodec.Failure.unsupportedVersion(2)) {
            try RemoteCodec.decode(data)
        }
    }

    @Test func garbageIsAnError() {
        #expect(throws: (any Error).self) {
            try RemoteCodec.decode(Data("not json".utf8))
        }
    }
}
