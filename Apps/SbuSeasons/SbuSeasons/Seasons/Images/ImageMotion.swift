/// Come cadono le immagini importate (SBU-230): come la neve, come le foglie (girano e planano), come la pioggia.
nonisolated enum ImageMotion: String, Codable, CaseIterable, Sendable {
    case snow, leaves, rain
}
