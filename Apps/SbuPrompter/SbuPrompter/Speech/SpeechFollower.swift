import AVFoundation
import Observation
import Speech

/// Listens to the microphone and turns speech into words, on the Mac only
/// (`requiresOnDeviceRecognition`). Feeds `onWords` and the voice level bar.
@Observable
final class SpeechFollower {
    enum Problem: Equatable {
        case denied, unavailable, noOnDeviceModel, microphone

        var message: LocalizedStringResource {
            switch self {
            case .denied: "Consenti microfono e riconoscimento vocale in Impostazioni di Sistema > Privacy e sicurezza."
            case .unavailable: "Il riconoscimento vocale non è disponibile per questa lingua."
            case .noOnDeviceModel: "Scarica la lingua della dettatura in Impostazioni di Sistema > Tastiera > Dettatura: Sbu Prompter riconosce la voce solo sul Mac."
            case .microphone: "Non riesco ad aprire il microfono."
            }
        }
    }

    /// 0...1, smoothed.
    private(set) var level: Double = 0
    private(set) var isListening = false
    private(set) var problem: Problem?
    /// The input being listened to, for the settings and the silence hint.
    private(set) var inputName: String?
    /// Listening, but nothing louder than room noise for a few seconds: maybe the wrong microphone.
    private(set) var isSilent = false

    static let silenceHintDelay: Duration = .seconds(5)

    @ObservationIgnored var onWords: ([String]) -> Void = { _ in }

    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private let current = RequestBox()
    @ObservationIgnored private var recognizer: SFSpeechRecognizer?
    @ObservationIgnored private var task: SFSpeechRecognitionTask?
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var lastHeard = ContinuousClock.now
    /// What the current listening uses, so a settings change can tell it must start again.
    @ObservationIgnored private(set) var localeIdentifier = ""
    @ObservationIgnored private(set) var microphone: String?
    @ObservationIgnored private var configurationObserver: (any NSObjectProtocol)?

    init() {
        // A microphone plugged in or out (AirPods, a USB mic) changes the engine's input: listen again on the new one.
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.restart() }
        }
    }

    /// `microphone` is a Core Audio UID; nil, or a device that is gone, means the system input.
    func start(localeIdentifier: String, microphone: String? = nil) async {
        guard !isListening else { return }
        self.localeIdentifier = localeIdentifier
        self.microphone = microphone
        problem = nil
        guard await Self.authorize() else { problem = .denied; return }
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: localeIdentifier)), recognizer.isAvailable else {
            problem = .unavailable
            return
        }
        guard recognizer.supportsOnDeviceRecognition else { problem = .noOnDeviceModel; return }
        self.recognizer = recognizer

        let input = engine.inputNode
        if let microphone, Microphones.select(microphone, on: input) {
            inputName = Microphones.name(of: microphone)
        } else {
            inputName = Microphones.systemDefaultName
        }
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0),
                         block: Self.makeTap(box: current) { [weak self] value in
                             Task { @MainActor in self?.updateLevel(value) }
                         })
        engine.prepare()
        do {
            try engine.start()
        } catch {
            input.removeTap(onBus: 0)
            problem = .microphone
            return
        }
        isListening = true
        lastHeard = .now
        isSilent = false
        startTask()
    }

    private func restart() {
        guard isListening else { return }
        stop()
        Task { await start(localeIdentifier: localeIdentifier, microphone: microphone) }
    }

    func stop() {
        guard isListening else { return }
        isListening = false
        generation += 1
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        current.set(nil)?.endAudio()
        task?.cancel()
        task = nil
        level = 0
        isSilent = false
    }

    /// A recognition task ends after a while or on an error: start a fresh one while listening.
    private func startTask() {
        guard isListening, let recognizer else { return }
        generation += 1
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        current.set(request)?.endAudio()
        task?.cancel()
        let id = generation
        task = recognizer.recognitionTask(with: request, resultHandler: Self.makeHandler { [weak self] text, isOver in
            Task { @MainActor in self?.received(text, isOver: isOver, generation: id) }
        })
    }

    private func received(_ text: String?, isOver: Bool, generation id: Int) {
        guard id == generation, isListening else { return }
        if let text { onWords(TextNormalizer.words(in: text)) }
        if isOver { startTask() }
    }

    private func updateLevel(_ value: Double) {
        guard isListening else { return }
        level = level * 0.6 + value * 0.4
        let now = ContinuousClock.now
        if value > 0.2 { lastHeard = now }
        let silent = now - lastHeard > Self.silenceHintDelay
        if silent != isSilent { isSilent = silent }
    }

    private nonisolated static func authorize() async -> Bool {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard speech == .authorized else { return false }
        return await AVCaptureDevice.requestAccess(for: .audio)
    }

    /// Runs on the audio thread: hands the buffer to the current request and measures the level.
    private nonisolated static func makeTap(box: RequestBox, level: @escaping @Sendable (Double) -> Void) -> AVAudioNodeTapBlock {
        { buffer, _ in
            box.append(buffer)
            guard let samples = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return }
            var sum: Float = 0
            for index in 0..<Int(buffer.frameLength) { sum += samples[index] * samples[index] }
            let rms = (sum / Float(buffer.frameLength)).squareRoot()
            // About -50 dB to -10 dB mapped onto 0...1.
            let decibels = 20 * log10(max(rms, 0.000_01))
            level(Double(min(max((decibels + 50) / 40, 0), 1)))
        }
    }

    private nonisolated static func makeHandler(
        _ handler: @escaping @Sendable (String?, Bool) -> Void
    ) -> (SFSpeechRecognitionResult?, (any Error)?) -> Void {
        { result, error in
            handler(result?.bestTranscription.formattedString, error != nil || result?.isFinal == true)
        }
    }
}

/// The request the audio tap writes into, swapped when a recognition task restarts.
/// Unchecked Sendable: every access goes through the lock.
private nonisolated final class RequestBox: @unchecked Sendable {
    private let lock = NSLock()
    private var request: SFSpeechAudioBufferRecognitionRequest?

    func append(_ buffer: AVAudioPCMBuffer) {
        lock.withLock { request?.append(buffer) }
    }

    /// Replaces the request and returns the previous one.
    @discardableResult
    func set(_ new: SFSpeechAudioBufferRecognitionRequest?) -> SFSpeechAudioBufferRecognitionRequest? {
        lock.withLock {
            let previous = request
            request = new
            return previous
        }
    }
}
