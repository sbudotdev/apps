import SbuKit
import SwiftUI

/// The colors of the pieces: the accents of eight sbu.dev apps (ADR-0015, as amended 18/10).
enum PieceTone {
    static let everyDay: [SbuAccent] = [.subscriptions, .scanner, .habits, .clean, .moon, .level, .libretto, .tidy]
    /// Christmas reds, greens and golds, still app accents: tone 1 is the tree, tone 2 its trunk.
    static let christmas: [SbuAccent] = [.libretto, .habits, .level, .cards, .meds, .ztl, .inventory, .gif]

    /// The palette of `season`.
    static func accents(in season: SbuSeason?) -> [SbuAccent] {
        season == .christmas ? christmas : everyDay
    }

    static func color(_ tone: Int, in season: SbuSeason? = nil) -> Color {
        let accents = accents(in: season)
        return accents[tone % accents.count].base
    }
}
