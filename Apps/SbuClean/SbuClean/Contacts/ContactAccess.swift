import Contacts

/// Whether the app may read the contacts, in the terms the finder cares about.
nonisolated enum ContactAccess: Equatable, Sendable {
    /// Not asked yet.
    case notDetermined
    /// Refused or restricted: only Settings can change it.
    case denied
    /// All the contacts, or the ones the user picked.
    case allowed

    init(status: CNAuthorizationStatus) {
        switch status {
        case .notDetermined: self = .notDetermined
        case .denied, .restricted: self = .denied
        default: self = .allowed
        }
    }
}
