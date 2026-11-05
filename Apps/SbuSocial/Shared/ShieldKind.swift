/// Which Shield an app shows.
nonisolated enum ShieldKind: Equatable {
    /// Everything is blocked now: the Shield only closes.
    case session
    /// The app has an Intenzione: the Shield counts its openings and can open it.
    case intention(Intention)
    /// Shielded with nothing to say about it.
    case plain
}
