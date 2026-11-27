import Testing
@testable import SbuPrompter

@MainActor
struct PrompterControllerTests {
    let text = """
    Uno due tre quattro.
    # Prima
    Cinque sei sette otto.
    Nove dieci undici.
    # Seconda
    Dodici tredici quattordici.
    """

    /// Lines 30 pt apart, a 60 pt viewport.
    func makeController(countdown: Int = 0) -> PrompterController {
        let controller = PrompterController()
        controller.countdownSeconds = countdown
        controller.load(text)
        controller.setLayout(lineOffsets: (0..<6).map { Double($0) * 30 }, contentHeight: 180, viewportHeight: 60)
        return controller
    }

    @Test func playStartsAfterTheCountdown() {
        let controller = makeController(countdown: 3)
        controller.perform(.togglePlay)
        #expect(controller.isPlaying)
        #expect(controller.countdownLeft == 3)
        controller.tick(1.5)
        #expect(controller.countdownLeft == 2)
        #expect(controller.engine.offset == 0)
        controller.tick(1.5)
        #expect(controller.countdownLeft == nil)
        controller.tick(0.5)
        #expect(controller.engine.offset == controller.engine.speed * 0.5)
    }

    @Test func toggleTwicePauses() {
        let controller = makeController()
        controller.perform(.togglePlay)
        controller.perform(.togglePlay)
        #expect(!controller.isPlaying)
        controller.tick(1)
        #expect(controller.engine.offset == 0)
    }

    @Test func hoverPausesWithoutStopping() {
        let controller = makeController()
        controller.perform(.togglePlay)
        controller.isHoverPaused = true
        controller.tick(1)
        #expect(controller.engine.offset == 0)
        #expect(controller.isPlaying)
        controller.isHoverPaused = false
        controller.tick(1)
        #expect(controller.engine.offset > 0)
    }

    @Test func speedCommands() {
        let controller = makeController()
        controller.perform(.setSpeed(40))
        controller.perform(.faster)
        #expect(controller.engine.speed == 50)
        controller.perform(.slower)
        controller.perform(.slower)
        #expect(controller.engine.speed == 35)
        controller.perform(.setSpeed(100))
        #expect(controller.engine.speed == 100)
    }

    @Test func jumpToACueAndBack() {
        let controller = makeController()
        controller.scrollManually(by: 15)
        controller.perform(.jumpToCue(1))
        #expect(controller.engine.offset == 120)
        #expect(controller.currentCue == 1)
        controller.perform(.returnFromCue)
        #expect(controller.engine.offset == 15)
        #expect(controller.canReturnFromCue == false)
    }

    @Test func nextAndPreviousCueFollowTheCurrentLine() {
        let controller = makeController()
        controller.perform(.nextCue)
        #expect(controller.currentCue == 0)
        controller.perform(.nextCue)
        #expect(controller.currentCue == 1)
        controller.perform(.previousCue)
        #expect(controller.currentCue == 0)
        // Return goes back to where the first jump started.
        controller.perform(.returnFromCue)
        #expect(controller.engine.offset == 0)
    }

    @Test func outOfRangeCueIsIgnored() {
        let controller = makeController()
        controller.perform(.jumpToCue(9))
        #expect(controller.engine.offset == 0)
    }

    /// SBU-424: going back on the Mac changes what the iPhone remote shows.
    @Test func scrollingBackOnTheMacChangesTheStatus() {
        let controller = makeController()
        let top = controller.status
        controller.scrollManually(by: 90)
        let ahead = controller.status
        #expect(ahead.currentLine != top.currentLine)
        controller.scrollManually(by: -90)
        #expect(controller.status.currentLine == top.currentLine)
    }

    /// SBU-424: the time on the iPhone follows the text when it is moved by hand, at the current speed.
    @Test func scrollingMovesTheReadingTime() {
        let controller = makeController()
        controller.speed = 40
        controller.perform(.togglePlay)
        controller.tick(2)
        #expect(controller.elapsed == 2)
        controller.scrollManually(by: -40)
        #expect(controller.elapsed == 1)
        controller.scrollManually(by: 20)
        #expect(controller.elapsed == 1.5)
        controller.scrollManually(by: -500)
        #expect(controller.elapsed == 0)
    }

    @Test func rewindStopsAtTheTop() {
        let controller = makeController()
        controller.perform(.togglePlay)
        controller.tick(1)
        controller.perform(.rewind)
        #expect(controller.engine.offset == 0)
        #expect(!controller.isPlaying)
        #expect(controller.elapsed == 0)
    }

    @Test func voiceModeFollowsTheReader() {
        let controller = makeController()
        controller.mode = .voice
        controller.perform(.togglePlay)
        controller.heard(TextNormalizer.words(in: "uno due tre quattro cinque sei"))
        #expect(controller.readWordCount == 6)
        #expect(controller.currentLine == 2)
        for _ in 0..<100 { controller.tick(0.05) }
        // Halfway through line 2 (top 60, next line at 90), with the reading line a fifth of the viewport down.
        #expect(abs(controller.engine.offset - (75 - 12)) < 0.5)
    }

    @Test(arguments: [(4, 48.0), (5, 55.5), (7, 70.5)])
    func voiceGlidesThroughALineWordByWord(heard: Int, target: Double) {
        let controller = makeController()
        controller.mode = .voice
        controller.perform(.togglePlay)
        let words = TextNormalizer.words(in: "uno due tre quattro cinque sei sette")
        controller.heard(Array(words.prefix(heard)))
        #expect(controller.voiceTarget == target)
    }

    @Test func voiceGlidesInsteadOfJumping() {
        let controller = makeController()
        controller.mode = .voice
        controller.perform(.togglePlay)
        controller.heard(TextNormalizer.words(in: "uno due tre quattro cinque sei"))
        controller.tick(1.0 / 60)
        // One frame covers a small part of the way, not most of it.
        #expect(controller.engine.offset > 0 && controller.engine.offset < controller.voiceTarget * 0.1)
    }

    @Test func voiceIsIgnoredWhilePaused() {
        let controller = makeController()
        controller.mode = .voice
        controller.heard(["uno", "due"])
        #expect(controller.readWordCount == 0)
    }

    @Test func voiceModeDoesNotScrollOnItsOwn() {
        let controller = makeController()
        controller.mode = .voice
        controller.perform(.togglePlay)
        controller.tick(2)
        #expect(controller.engine.offset == 0)
    }

    @Test func manualScrollMovesTheVoicePosition() {
        let controller = makeController()
        controller.mode = .voice
        controller.scrollManually(by: 90)
        #expect(controller.readWordCount == 8)
    }

    @Test func statusDescribesTheCurrentState() {
        let controller = makeController()
        controller.perform(.jumpToCue(1))
        let status = controller.status
        #expect(status.cueTitles == ["Prima", "Seconda"])
        #expect(status.currentCue == 1)
        #expect(status.currentLine == "Seconda")
        #expect(status.isPlaying == false)
    }

    @Test func reloadingKeepsThePositionInRange() {
        let controller = makeController()
        controller.scrollManually(by: 100)
        controller.load("Una riga sola.")
        controller.setLayout(lineOffsets: [0], contentHeight: 30, viewportHeight: 60)
        #expect(controller.engine.offset == 0)
        #expect(controller.currentLine == 0)
    }

    @Test func switchingToVoiceKeepsThePlace() {
        let controller = makeController()
        controller.perform(.togglePlay)
        controller.tick(3) // 40 pt/s: at the end, 120 pt
        #expect(controller.engine.offset == 120)
        controller.mode = .voice
        controller.tick(1)
        #expect(controller.engine.offset > 90)
    }

    @Test func fixedModeStopsAtTheEnd() {
        let controller = makeController()
        controller.perform(.togglePlay)
        controller.tick(5)
        #expect(controller.engine.isAtEnd)
        #expect(!controller.isPlaying)
        let elapsed = controller.elapsed
        controller.tick(1)
        #expect(controller.elapsed == elapsed)
    }

    /// The panel's own button calls the controller: the app must still hear about it
    /// to restart the frame clock and turn the microphone on or off.
    @Test func reportsPlayStateChanges() {
        let controller = makeController()
        var changes: [Bool] = []
        controller.onPlayingChange = { changes.append(controller.isPlaying) }
        controller.perform(.togglePlay)
        controller.perform(.togglePlay)
        controller.pause()
        #expect(changes == [true, false])
    }
}
