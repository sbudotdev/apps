import CoreGraphics

/// How the prompter is framed: hanging from the notch, as a pill, or as a free window.
nonisolated enum PrompterChrome: Equatable {
    /// `width` is the notch's: beside it, the menu bar row stays free.
    case notch(height: CGFloat, width: CGFloat)
    case pill
    case floating

    /// Room left at the top for the camera housing.
    var topInset: CGFloat {
        if case .notch(let height, _) = self { height } else { 0 }
    }

    /// Whether a point on screen (AppKit coordinates, y up) is on the prompter itself.
    /// Beside the notch, in the menu bar row, the panel is empty: clicks go to the menu bar.
    func contains(_ point: CGPoint, panelFrame frame: CGRect) -> Bool {
        guard frame.contains(point) else { return false }
        guard case .notch(let height, let width) = self, point.y > frame.maxY - height else { return true }
        return abs(point.x - frame.midX) <= width / 2
    }
}
