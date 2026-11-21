/// A snapshot of the prompter, for the menu and, later, the iPhone remote.
nonisolated struct PrompterStatus: Codable, Sendable, Equatable {
    var isPlaying: Bool
    /// Points per second.
    var speed: Double
    var isVoice: Bool
    var cueTitles: [String?]
    var currentCue: Int?
    var currentLine: String
    /// Seconds spent reading (scrolling), countdown and pauses excluded.
    var elapsed: Double
    var countdownLeft: Int?
}
