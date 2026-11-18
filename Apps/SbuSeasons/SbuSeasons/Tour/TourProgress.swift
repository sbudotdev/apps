import Foundation

/// Se il tour è già stato visto e quali cose da provare sono fatte. Salvato in UserDefaults.
@Observable
final class TourProgress {
    static let shared = TourProgress()

    private let defaults: UserDefaults
    private(set) var done: Set<TourChallenge>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        done = Set((defaults.stringArray(forKey: "tourDone") ?? []).compactMap(TourChallenge.init(rawValue:)))
    }

    /// Alla prima apertura il tour si apre da solo, una volta.
    var opensAtLaunch: Bool { !defaults.bool(forKey: "tourSeen") }
    var allDone: Bool { done.count == TourChallenge.allCases.count }

    func markSeen() { defaults.set(true, forKey: "tourSeen") }

    func complete(_ challenge: TourChallenge) {
        guard done.insert(challenge).inserted else { return }
        defaults.set(done.map(\.rawValue).sorted(), forKey: "tourDone")
    }
}
