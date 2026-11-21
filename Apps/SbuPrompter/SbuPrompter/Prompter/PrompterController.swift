import Observation

/// The prompter's state and rules: play, pause, speed, cues, countdown and voice following.
/// The view reports where each line sits (`setLayout`) and calls `tick` on every frame.
@Observable
final class PrompterController {
    enum Mode: String, CaseIterable, Codable {
        case fixed, voice
    }

    /// The reading line sits this fraction of the viewport below the top edge.
    static let readingAnchor = 0.2

    private(set) var script = ParsedScript("")
    var mode: Mode = .fixed {
        // Fixed mode leaves the aligner behind: voice must start from the line on screen.
        didSet { if mode != oldValue { syncVoicePositionToOffset() } }
    }
    var countdownSeconds = 3
    private(set) var isPlaying = false {
        didSet { if isPlaying != oldValue { onPlayingChange?() } }
    }
    /// Called whenever play starts or stops, whoever asked (menu, shortcut, panel button, end of text).
    @ObservationIgnored var onPlayingChange: (() -> Void)?
    /// The pointer is over the prompter: stop while it stays there.
    var isHoverPaused = false
    private(set) var countdownLeft: Int?
    private(set) var engine = ScrollEngine(speed: 40, maxOffset: 0)
    private(set) var elapsed: Double = 0

    private var aligner = ScriptAligner(script: [])
    private var countdownElapsed: Double = 0
    private var returnPoint: (offset: Double, word: Int)?
    private var lineOffsets: [Double] = []
    private var viewportHeight: Double = 0

    var speed: Double {
        get { engine.speed }
        set { engine.speed = newValue }
    }

    /// The text is actually moving (or following the voice) right now.
    var isMoving: Bool { isPlaying && countdownLeft == nil && !isHoverPaused }
    var readWordCount: Int { aligner.position }
    var canReturnFromCue: Bool { returnPoint != nil }

    var currentLine: Int {
        guard !script.lines.isEmpty else { return 0 }
        if mode == .voice { return script.line(containingWord: aligner.position) }
        return line(atOffset: engine.offset)
    }

    var currentCue: Int? { script.cueIndex(atLine: currentLine) }

    var status: PrompterStatus {
        PrompterStatus(
            isPlaying: isPlaying, speed: engine.speed, isVoice: mode == .voice,
            cueTitles: script.cues.map(\.title), currentCue: currentCue,
            currentLine: script.lines.isEmpty ? "" : script.lines[currentLine].text,
            elapsed: elapsed, countdownLeft: countdownLeft)
    }

    func load(_ text: String) {
        script = ParsedScript(text)
        aligner = ScriptAligner(script: script.words, position: aligner.position)
        returnPoint = nil
    }

    func setLayout(lineOffsets: [Double], contentHeight: Double, viewportHeight: Double) {
        self.lineOffsets = lineOffsets
        self.viewportHeight = viewportHeight
        engine.maxOffset = max(0, contentHeight - viewportHeight)
    }

    func perform(_ command: PrompterCommand) {
        switch command {
        case .togglePlay: isPlaying ? pause() : play()
        case .faster: engine.faster()
        case .slower: engine.slower()
        case .setSpeed(let speed): engine.speed = speed
        case .nextCue:
            if let cue = script.nextCue(afterLine: currentLine) { jump(toCue: cue) }
        case .previousCue:
            if let cue = script.previousCue(beforeLine: currentLine) { jump(toCue: cue) }
        case .jumpToCue(let cue): jump(toCue: cue)
        case .returnFromCue: returnFromCue()
        case .rewind: rewind()
        case .toggleVisibility: break // the window belongs to the app model
        }
    }

    func play() {
        guard !isPlaying else { return }
        isPlaying = true
        countdownElapsed = 0
        countdownLeft = Countdown(seconds: countdownSeconds).remaining(after: 0)
    }

    func pause() {
        isPlaying = false
        countdownLeft = nil
    }

    /// Advances the countdown and the text by `seconds` of wall time.
    func tick(_ seconds: Double) {
        guard isPlaying else { return }
        if countdownLeft != nil {
            countdownElapsed += seconds
            countdownLeft = Countdown(seconds: countdownSeconds).remaining(after: countdownElapsed)
            return
        }
        guard !isHoverPaused else { return }
        elapsed += seconds
        switch mode {
        case .fixed:
            engine.advance(by: seconds)
            if engine.isAtEnd { pause() }
        case .voice: engine.approach(targetOffset(forLine: currentLine), by: seconds)
        }
    }

    /// Normalized words heard so far, in voice mode.
    func heard(_ words: [String]) {
        guard mode == .voice, isMoving else { return }
        aligner.update(spoken: words)
    }

    /// Trackpad or wheel scrolling, in points (positive goes forward).
    func scrollManually(by points: Double) {
        engine.scroll(by: points)
        syncVoicePositionToOffset()
    }

    private func jump(toCue index: Int) {
        guard script.cues.indices.contains(index) else { return }
        if returnPoint == nil { returnPoint = (engine.offset, aligner.position) }
        let cue = script.cues[index]
        engine.scroll(to: offset(ofLine: cue.lineIndex))
        aligner.reset(to: cue.wordIndex)
    }

    private func returnFromCue() {
        guard let point = returnPoint else { return }
        engine.scroll(to: point.offset)
        aligner.reset(to: point.word)
        returnPoint = nil
    }

    private func rewind() {
        pause()
        engine.rewind()
        aligner.reset(to: 0)
        elapsed = 0
        returnPoint = nil
    }

    private func syncVoicePositionToOffset() {
        guard !script.lines.isEmpty else { return }
        aligner.reset(to: script.lines[line(atOffset: engine.offset)].wordRange.lowerBound)
    }

    private var anchor: Double { viewportHeight * Self.readingAnchor }

    private func offset(ofLine line: Int) -> Double {
        lineOffsets.indices.contains(line) ? lineOffsets[line] : 0
    }

    private func targetOffset(forLine line: Int) -> Double {
        offset(ofLine: line) - anchor
    }

    private func line(atOffset offset: Double) -> Int {
        let reading = offset + anchor
        let index = lineOffsets.lastIndex { $0 <= reading } ?? 0
        return min(index, max(script.lines.count - 1, 0))
    }
}
