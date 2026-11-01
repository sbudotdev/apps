import Foundation

/// The answer for one vehicle, one zone, one moment.
nonisolated enum Access: Sendable, Equatable {
    /// The zone is not in force at this time.
    case off
    /// In force, and this vehicle may enter.
    case allowed
    /// In force, and this vehicle pays to enter.
    case paid(euros: Decimal)
    case forbidden
    /// The sources don't settle it: the app says so instead of answering.
    case unknown

    /// Whether the navigator keeps out. Paying is the user's choice; not knowing counts as no.
    func avoided(avoidingPaid: Bool) -> Bool {
        switch self {
        case .off, .allowed: false
        case .paid: avoidingPaid
        case .forbidden, .unknown: true
        }
    }
}
