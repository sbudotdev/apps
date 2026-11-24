import AVFoundation
import OSLog

/// Plays the key samples with as little delay as possible.
///
/// Every sample of the current switch is decoded in memory. A small pool of voices takes turns,
/// so fast typing overlaps instead of cutting the previous key; each voice has its own pitch
/// (a little random, like real keys) and pan (where the key sits).
final class KeySoundPlayer {
    private struct Voice {
        let player = AVAudioPlayerNode()
        let pitch = AVAudioUnitVarispeed()
        let mixer = AVAudioMixerNode()
    }

    private static let voiceCount = 8
    private static let pitchRange: ClosedRange<Float> = 0.96...1.04
    private let logger = Logger(subsystem: "dev.sbu.keys", category: "audio")

    private let engine = AVAudioEngine()
    private let voices = (0..<voiceCount).map { _ in Voice() }
    private var nextVoice = 0
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var format: AVAudioFormat?
    private var configurationObserver: NSObjectProtocol?

    var volume: Float {
        get { engine.mainMixerNode.outputVolume }
        set { engine.mainMixerNode.outputVolume = newValue }
    }

    init() {
        // Headphones in or out change the output format: the engine stops and is rebuilt.
        configurationObserver = NotificationCenter.default.addObserver(
            forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.restart() }
        }
    }

    /// Loads the samples of `keySwitch` from `Sounds/` in the bundle.
    func load(_ keySwitch: KeySwitch) {
        var loaded: [String: AVAudioPCMBuffer] = [:]
        for kind in KeyKind.allCases {
            for isDown in [true, false] {
                let name = keySwitch.soundName(for: kind, isDown: isDown)
                guard let url = Bundle.main.url(forResource: name, withExtension: "caf"),
                      let file = try? AVAudioFile(forReading: url),
                      let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
                      (try? file.read(into: buffer)) != nil
                else {
                    logger.error("Missing sample \(name, privacy: .public)")
                    continue
                }
                loaded[name] = buffer
            }
        }
        buffers = loaded
        if let first = loaded.values.first?.format, first != format {
            format = first
            connect(first)
        }
    }

    func play(_ kind: KeyKind, keySwitch: KeySwitch, isDown: Bool, pan: Float) {
        guard let buffer = buffers[keySwitch.soundName(for: kind, isDown: isDown)] else { return }
        if !engine.isRunning { restart() }
        let voice = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count
        voice.mixer.pan = pan
        voice.pitch.rate = Float.random(in: Self.pitchRange)
        voice.player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !voice.player.isPlaying { voice.player.play() }
    }

    func stop() {
        engine.stop()
    }

    private func connect(_ format: AVAudioFormat) {
        engine.stop()
        for voice in voices {
            if voice.player.engine == nil {
                engine.attach(voice.player)
                engine.attach(voice.pitch)
                engine.attach(voice.mixer)
            }
            engine.connect(voice.player, to: voice.pitch, format: format)
            engine.connect(voice.pitch, to: voice.mixer, format: format)
            engine.connect(voice.mixer, to: engine.mainMixerNode, format: nil)
        }
        restart()
    }

    private func restart() {
        engine.prepare()
        do {
            try engine.start()
        } catch {
            logger.error("Audio engine did not start: \(error.localizedDescription, privacy: .public)")
        }
    }
}
