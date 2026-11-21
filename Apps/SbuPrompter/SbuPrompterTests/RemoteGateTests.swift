import Foundation
import Testing
@testable import SbuPrompter

final class Clock {
    var now = Date(timeIntervalSince1970: 0)
}

struct RemoteGateTests {
    private func gate(tokens: Set<String> = [], clock: Clock = Clock()) -> RemoteGate<String> {
        var codes = ["1234", "5678", "9012", "3456"].makeIterator()
        return RemoteGate(tokens: tokens, makeCode: { codes.next() ?? "0000" }, makeToken: { "token" },
                          now: { clock.now })
    }

    private func failAll(_ gate: inout RemoteGate<String>) {
        for _ in 0..<RemoteGate<String>.maxFailures { _ = gate.receive(.pair(code: "0000"), from: "iPhone") }
    }

    @Test func rightCodePairsAndSendsStatus() {
        var gate = gate()
        #expect(gate.receive(.pair(code: "1234"), from: "iPhone") == [.send(.paired(token: "token")), .sendStatus])
        #expect(gate.isTrusted("iPhone"))
        #expect(gate.tokens == ["token"])
    }

    @Test func codeIsUsedOnlyOnce() {
        var gate = gate()
        _ = gate.receive(.pair(code: "1234"), from: "iPhone")
        #expect(gate.code == "5678")
        #expect(gate.receive(.pair(code: "1234"), from: "Other") == [.send(.pairingRequired)])
        #expect(!gate.isTrusted("Other"))
    }

    @Test func wrongCodeIsRefused() {
        var gate = gate()
        #expect(gate.receive(.pair(code: "0000"), from: "iPhone") == [.send(.pairingRequired)])
        #expect(!gate.isTrusted("iPhone"))
    }

    @Test func tooManyWrongCodesChangeTheCode() {
        var gate = gate()
        for _ in 1..<RemoteGate<String>.maxFailures {
            _ = gate.receive(.pair(code: "0000"), from: "iPhone")
            #expect(gate.code == "1234")
        }
        _ = gate.receive(.pair(code: "0000"), from: "iPhone")
        #expect(gate.code == "5678")
        #expect(gate.receive(.pair(code: "1234"), from: "iPhone") == [.send(.pairingRequired)])
    }

    @Test func tooManyWrongCodesCloseThePairingForAWhile() {
        let clock = Clock()
        var gate = gate(clock: clock)
        failAll(&gate)
        // Even the right new code is refused during the pause.
        #expect(gate.receive(.pair(code: "5678"), from: "iPhone") == [.send(.pairingRequired)])
        clock.now += RemoteGate<String>.firstLockout
        #expect(gate.receive(.pair(code: "5678"), from: "iPhone") == [.send(.paired(token: "token")), .sendStatus])
    }

    @Test func thePauseDoublesUntilAPairingSucceeds() {
        let clock = Clock()
        var gate = gate(clock: clock)
        failAll(&gate)
        clock.now += RemoteGate<String>.firstLockout
        failAll(&gate)
        clock.now += RemoteGate<String>.firstLockout
        #expect(gate.receive(.pair(code: "9012"), from: "iPhone") == [.send(.pairingRequired)])
        clock.now += RemoteGate<String>.firstLockout
        #expect(gate.receive(.pair(code: "9012"), from: "iPhone") == [.send(.paired(token: "token")), .sendStatus])
    }

    @Test func forgettingEndsThePause() {
        var gate = gate()
        failAll(&gate)
        gate.forgetAll()
        #expect(gate.receive(.pair(code: gate.code), from: "iPhone") == [.send(.paired(token: "token")), .sendStatus])
    }

    @Test func savedTokensStillWorkDuringThePause() {
        var gate = gate(tokens: ["saved"])
        failAll(&gate)
        #expect(gate.receive(.resume(token: "saved"), from: "iPad") == [.send(.paired(token: "saved")), .sendStatus])
    }

    @Test func knownTokenResumesWithoutCode() {
        var gate = gate(tokens: ["saved"])
        #expect(gate.receive(.resume(token: "saved"), from: "iPhone") == [.send(.paired(token: "saved")), .sendStatus])
        #expect(gate.isTrusted("iPhone"))
    }

    @Test func unknownTokenAsksForTheCode() {
        var gate = gate(tokens: ["saved"])
        #expect(gate.receive(.resume(token: "stolen"), from: "iPhone") == [.send(.pairingRequired)])
        #expect(!gate.isTrusted("iPhone"))
    }

    @Test func commandsRunOnlyFromTrustedPeers() {
        var gate = gate()
        #expect(gate.receive(.command(.togglePlay), from: "iPhone") == [.send(.pairingRequired)])
        _ = gate.receive(.pair(code: "1234"), from: "iPhone")
        #expect(gate.receive(.command(.togglePlay), from: "iPhone") == [.perform(.togglePlay)])
    }

    @Test func disconnectingDropsTrust() {
        var gate = gate()
        _ = gate.receive(.pair(code: "1234"), from: "iPhone")
        gate.disconnected("iPhone")
        #expect(!gate.isTrusted("iPhone"))
        #expect(!gate.hasTrustedPeer)
    }

    @Test func forgettingDropsTokensAndPeers() {
        var gate = gate(tokens: ["saved"])
        _ = gate.receive(.resume(token: "saved"), from: "iPhone")
        gate.forgetAll()
        #expect(gate.tokens.isEmpty)
        #expect(!gate.isTrusted("iPhone"))
    }

    @Test(arguments: [RemoteMessage.paired(token: "x"), .pairingRequired, .status(RemoteCodecTests.status)])
    func macIgnoresMessagesMeantForTheIPhone(_ message: RemoteMessage) {
        var gate = gate()
        #expect(gate.receive(message, from: "iPhone").isEmpty)
    }

    @Test func randomCodeHasFourDigits() {
        for _ in 0..<50 {
            let code = RemoteGate<String>.randomCode()
            #expect(code.count == 4 && code.allSatisfy(\.isNumber))
        }
    }
}
