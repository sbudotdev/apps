import Foundation

/// What the driver does at a step.
nonisolated enum Maneuver: String, Codable, Sendable {
    case depart, straight, slightLeft, left, sharpLeft, slightRight, right, sharpRight, uTurn, arrive

    var symbol: String {
        switch self {
        case .depart, .straight: "arrow.up"
        case .slightLeft: "arrow.up.left"
        case .left, .sharpLeft: "arrow.turn.up.left"
        case .slightRight: "arrow.up.right"
        case .right, .sharpRight: "arrow.turn.up.right"
        case .uTurn: "arrow.uturn.down"
        case .arrive: "mappin"
        }
    }

    /// From the change of heading, in degrees: negative is left.
    static func turn(degrees: Double) -> Maneuver {
        switch degrees {
        case -25...25: .straight
        case -60 ..< -25: .slightLeft
        case -120 ..< -60: .left
        case -165 ..< -120: .sharpLeft
        case 25..<60: .slightRight
        case 60..<120: .right
        case 120..<165: .sharpRight
        default: .uTurn
        }
    }
}
