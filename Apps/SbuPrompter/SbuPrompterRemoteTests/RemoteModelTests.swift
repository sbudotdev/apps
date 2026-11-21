import Foundation
import SwiftUI
import Testing
@testable import SbuPrompterRemote

@MainActor
struct RemoteModelTests {
    let defaults: UserDefaults
    let model: RemoteModel
    let sent: Sent

    final class Sent {
        var messages: [RemoteMessage] = []
        var macs: [String] = []
    }

    init() {
        let suite = "RemoteModelTests-\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite) ?? .standard
        defaults.removePersistentDomain(forName: suite)
        model = RemoteModel(defaults: defaults)
        sent = Sent()
        model.send = { [sent] in sent.messages.append($0) }
        model.connect = { [sent] in sent.macs.append($0) }
    }

    static let status = PrompterStatus(isPlaying: true, speed: 40, isVoice: false, cueTitles: ["A", nil],
                                       currentCue: 0, currentLine: "Ciao", elapsed: 65, countdownLeft: nil)

    @Test func startsSearching() {
        #expect(model.phase == .searching)
    }

    @Test func oneMacFoundIsJoinedRightAway() {
        model.found(["Studio"])
        #expect(sent.macs == ["Studio"])
        #expect(model.phase == .connecting("Studio"))
    }

    @Test func severalMacsWaitForAChoice() {
        model.found(["Studio", "Portatile"])
        #expect(sent.macs.isEmpty)
        #expect(model.macs == ["Portatile", "Studio"])
        model.choose("Portatile")
        #expect(sent.macs == ["Portatile"])
    }

    @Test func aPairedMacIsPreferredAmongSeveral() {
        model.found(["Studio"])
        model.connected(to: "Studio")
        model.receive(.paired(token: "t1"))
        model.disconnected(from: "Studio")
        sent.macs = []
        model.found(["Portatile", "Studio"])
        #expect(sent.macs == ["Studio"])
    }

    @Test func firstConnectionAsksForTheCode() {
        model.found(["Studio"])
        model.connected(to: "Studio")
        #expect(model.phase == .needsCode(mac: "Studio", wrong: false))
        #expect(sent.messages.isEmpty)
    }

    @Test func rightCodePairsAndKeepsTheToken() {
        model.found(["Studio"])
        model.connected(to: "Studio")
        model.enter(code: "1234")
        #expect(sent.messages == [.pair(code: "1234")])
        model.receive(.paired(token: "t1"))
        #expect(model.phase == .connected("Studio"))

        let again = RemoteModel(defaults: defaults)
        var messages: [RemoteMessage] = []
        again.send = { messages.append($0) }
        again.found(["Studio"])
        again.connected(to: "Studio")
        #expect(messages == [.resume(token: "t1")])
        #expect(again.phase == .connecting("Studio"))
    }

    @Test func wrongCodeSaysSo() {
        model.found(["Studio"])
        model.connected(to: "Studio")
        model.enter(code: "0000")
        model.receive(.pairingRequired)
        #expect(model.phase == .needsCode(mac: "Studio", wrong: true))
    }

    @Test func refusedTokenIsForgottenAndTheCodeAsked() {
        model.found(["Studio"])
        model.connected(to: "Studio")
        model.enter(code: "1234")
        model.receive(.paired(token: "t1"))
        model.disconnected(from: "Studio")
        model.connected(to: "Studio")
        model.receive(.pairingRequired)
        #expect(model.phase == .needsCode(mac: "Studio", wrong: false))
        #expect(!model.isPaired(with: "Studio"))
    }

    @Test(arguments: ["12", "12345", "12a4", ""])
    func onlyFourDigitsAreSent(_ code: String) {
        model.found(["Studio"])
        model.connected(to: "Studio")
        model.enter(code: code)
        #expect(sent.messages.isEmpty)
    }

    @Test func statusIsShown() {
        pair()
        model.receive(.status(Self.status))
        #expect(model.status == Self.status)
    }

    @Test func commandsAreSentOnlyWhenPairedAndCounted() {
        model.perform(.togglePlay)
        #expect(sent.messages.isEmpty)
        pair()
        sent.messages = []
        model.perform(.togglePlay)
        model.perform(.nextCue)
        #expect(sent.messages == [.command(.togglePlay), .command(.nextCue)])
        #expect(model.commandCount == 2)
    }

    @Test func losingTheMacGoesBackToSearching() {
        pair()
        model.receive(.status(Self.status))
        model.disconnected(from: "Studio")
        #expect(model.phase == .searching)
        #expect(model.status == nil)
    }

    @Test func aFailedInvitationIsRetriedThenGivesUp() {
        model.found(["Studio"])
        for _ in 1..<RemoteModel.maxAttempts {
            model.disconnected(from: "Studio")
            #expect(model.phase == .connecting("Studio"))
        }
        #expect(sent.macs.count == RemoteModel.maxAttempts)
        model.disconnected(from: "Studio")
        #expect(model.phase == .searching)
    }

    @Test func anotherMacDroppingIsIgnored() {
        pair()
        model.disconnected(from: "Portatile")
        #expect(model.phase == .connected("Studio"))
    }

    @Test func forgettingTheMacDropsTheToken() {
        pair()
        model.forget("Studio")
        #expect(!model.isPaired(with: "Studio"))
    }

    @Test func anOutdatedMacIsExplained() {
        model.found(["Studio"])
        model.outdated()
        #expect(model.phase == .outdated)
    }

    @Test(arguments: [
        (CGSize(width: 0, height: -80), PrompterCommand.faster),
        (CGSize(width: 0, height: 80), .slower),
        (CGSize(width: -80, height: 10), .nextCue),
        (CGSize(width: 80, height: -10), .previousCue),
    ])
    func swipesMapToCommands(_ translation: CGSize, _ command: PrompterCommand) {
        #expect(RemoteModel.command(forSwipe: translation) == command)
    }

    @Test func shortDragsAreNotSwipes() {
        #expect(RemoteModel.command(forSwipe: CGSize(width: 10, height: 12)) == nil)
    }

    @Test(arguments: [CGSize.zero, CGSize(width: 3, height: -4)])
    func dragsThatBarelyMoveAreTaps(_ translation: CGSize) {
        #expect(RemoteModel.command(forSwipe: translation) == .togglePlay)
    }

    // MARK: Scene, screen lock, pairing replies (QA SBU-173)

    @Test func theLinkStartsAtLaunchButSurvivesTheControlCenter() {
        #expect(model.sceneChanged(to: .active))
        // Control Center, a notification, the app switcher glance: inactive, never background.
        #expect(!model.sceneChanged(to: .inactive))
        #expect(!model.sceneChanged(to: .active))
    }

    @Test func theLinkStartsAgainBackFromTheBackground() {
        _ = model.sceneChanged(to: .active)
        _ = model.sceneChanged(to: .inactive)
        #expect(!model.sceneChanged(to: .background))
        #expect(!model.sceneChanged(to: .inactive))
        #expect(model.sceneChanged(to: .active))
        #expect(!model.sceneChanged(to: .active))
    }

    @Test func theScreenStaysOnOnlyWhileConnectedAndInFront() {
        _ = model.sceneChanged(to: .active)
        #expect(!model.keepsScreenOn)
        pair()
        #expect(model.keepsScreenOn)
        _ = model.sceneChanged(to: .inactive)
        #expect(model.keepsScreenOn)
        _ = model.sceneChanged(to: .background)
        #expect(!model.keepsScreenOn)
        _ = model.sceneChanged(to: .active)
        #expect(model.keepsScreenOn)
        model.disconnected(from: "Studio")
        #expect(!model.keepsScreenOn)
    }

    @Test func everyWrongCodeIsCountedSoTheFieldEmptiesEachTime() {
        model.found(["Studio"])
        model.connected(to: "Studio")
        for attempt in 1...3 {
            model.enter(code: "0000")
            model.receive(.pairingRequired)
            #expect(model.wrongCodes == attempt)
        }
        // A refused token is not a wrong code.
        model.receive(.pairingRequired)
        #expect(model.wrongCodes == 3)
    }

    @Test func aPausedMacAsksToWait() {
        model.found(["Studio"])
        model.connected(to: "Studio")
        model.enter(code: "1234")
        model.receive(.pairingPaused)
        #expect(model.phase == .needsCode(mac: "Studio", wrong: true))
        #expect(model.isPairingPaused)
        #expect(model.wrongCodes == 1)
        model.enter(code: "5678")
        model.receive(.paired(token: "t1"))
        #expect(!model.isPairingPaused)
    }

    @Test func twoMacsWithTheSameNameGetDifferentLabels() {
        #expect(MacLink.label(for: "Studio", taken: []) == "Studio")
        #expect(MacLink.label(for: "Studio", taken: ["Studio"]) == "Studio (2)")
        #expect(MacLink.label(for: "Studio", taken: ["Studio", "Studio (2)"]) == "Studio (3)")
    }

    private func pair() {
        model.found(["Studio"])
        model.connected(to: "Studio")
        model.enter(code: "1234")
        model.receive(.paired(token: "t1"))
    }
}
