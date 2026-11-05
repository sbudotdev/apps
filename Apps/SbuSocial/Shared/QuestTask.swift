/// The three tasks of the Missione del giorno.
nonisolated enum QuestTask: String, Codable, CaseIterable {
    /// Look at how yesterday went.
    case review
    /// Read the tip of the day.
    case tip
    /// Finish a block: Blocca ora or a Sessione.
    case block
}
