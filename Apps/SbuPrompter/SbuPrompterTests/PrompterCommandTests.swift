import Foundation
import Testing
@testable import SbuPrompter

struct PrompterCommandTests {
    @Test(arguments: [
        PrompterCommand.togglePlay, .faster, .slower, .setSpeed(55), .nextCue, .previousCue,
        .jumpToCue(2), .returnFromCue, .rewind, .toggleVisibility,
    ])
    func commandsRoundTripThroughJSON(_ command: PrompterCommand) throws {
        let data = try JSONEncoder().encode(command)
        #expect(try JSONDecoder().decode(PrompterCommand.self, from: data) == command)
    }

    @Test func statusRoundTripsThroughJSON() throws {
        let status = PrompterStatus(isPlaying: true, speed: 40, isVoice: false, cueTitles: ["A", "B"],
                                    currentCue: 1, currentLine: "Ciao", elapsed: 12, countdownLeft: nil)
        let data = try JSONEncoder().encode(status)
        #expect(try JSONDecoder().decode(PrompterStatus.self, from: data) == status)
    }
}
