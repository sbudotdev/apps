import Foundation

/// The words for a step, on screen and aloud.
nonisolated enum ManeuverText {
    static func action(_ step: RouteStep) -> String {
        if let instruction = step.instruction { return instruction }
        return switch step.maneuver {
        case .depart: String(localized: "Parti")
        case .straight: String(localized: "Prosegui")
        case .slightLeft: String(localized: "Tieni la sinistra")
        case .left: String(localized: "Svolta a sinistra")
        case .sharpLeft: String(localized: "Svolta tutto a sinistra")
        case .slightRight: String(localized: "Tieni la destra")
        case .right: String(localized: "Svolta a destra")
        case .sharpRight: String(localized: "Svolta tutto a destra")
        case .uTurn: String(localized: "Inverti la marcia")
        case .arrive: String(localized: "Sei a destinazione")
        }
    }

    static func spoken(_ step: RouteStep, metres: Int) -> String {
        let action = action(step)
        if let street = step.street {
            return String(localized: "Tra \(metres) metri, \(action), \(street)")
        }
        return String(localized: "Tra \(metres) metri, \(action)")
    }
}
