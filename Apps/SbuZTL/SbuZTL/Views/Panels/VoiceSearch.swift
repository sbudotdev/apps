import AVFoundation
import Observation
import Speech
import SwiftUI

/// Voice search, recognized on the iPhone only: the audio never leaves it (ADR-0019 stays as it is).
@Observable
final class VoiceSearch {
    private(set) var isListening = false
    private(set) var problem: LocalizedStringKey?

    private let engine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognition: SFSpeechRecognitionTask?
    private var silence: Task<Void, Never>?

    /// Listens until you stop or stay silent for two seconds, handing over the text so far.
    func listen(onText: (String) -> Void) async {
        problem = nil
        // Italian whatever the language of the iPhone: the places are Italian.
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "it-IT")), recognizer.supportsOnDeviceRecognition else {
            problem = "Il riconoscimento sull'iPhone non è disponibile. Usa il microfono della tastiera."
            return
        }
        guard await Self.isAuthorized() else {
            problem = "Permetti microfono e riconoscimento vocale nelle Impostazioni."
            return
        }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.requiresOnDeviceRecognition = true
        request.shouldReportPartialResults = true
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            Self.installTap(on: engine.inputNode, request: request)
            engine.prepare()
            try engine.start()
        } catch {
            problem = "Non riesco a usare il microfono."
            stop()
            return
        }
        self.request = request
        isListening = true
        let (texts, continuation) = AsyncStream.makeStream(of: String.self)
        recognition = Self.recognize(request, with: recognizer, into: continuation)
        for await text in texts {
            onText(text)
            silence?.cancel()
            silence = Task {
                try? await Task.sleep(for: .seconds(2))
                if !Task.isCancelled { stop() }
            }
        }
        stop()
    }

    func stop() {
        silence?.cancel()
        guard engine.isRunning || isListening else { return }
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        recognition?.finish()
        request = nil
        recognition = nil
        isListening = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // The audio and speech callbacks run off the main actor: these stay nonisolated, or they would trap.
    private nonisolated static func installTap(on input: AVAudioInputNode, request: SFSpeechAudioBufferRecognitionRequest) {
        input.installTap(onBus: 0, bufferSize: 1024, format: input.outputFormat(forBus: 0)) { buffer, _ in
            request.append(buffer)
        }
    }

    private nonisolated static func recognize(_ request: SFSpeechAudioBufferRecognitionRequest, with recognizer: SFSpeechRecognizer, into continuation: AsyncStream<String>.Continuation) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { result, error in
            if let result { continuation.yield(result.bestTranscription.formattedString) }
            if error != nil || result?.isFinal == true { continuation.finish() }
        }
    }

    private nonisolated static func isAuthorized() async -> Bool {
        let speech = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard speech == .authorized else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }
}
