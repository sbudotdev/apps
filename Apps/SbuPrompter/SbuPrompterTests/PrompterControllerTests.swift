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
        let start = controller.engine.speed
        controller.perform(.faster)
        #expect(controller.engine.speed == start + ScrollEngine.speedStep)
        controller.perform(.slower)
        controller.perform(.slower)
        #expect(controller.engine.speed == start - ScrollEngine.speedStep)
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
        // Line 2 sits a fifth of the viewport below the top.
        #expect(abs(controller.engine.offset - (60 - 12)) < 0.5)
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
}
