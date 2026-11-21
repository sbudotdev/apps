import CoreGraphics

/// How the prompter is framed: hanging from the notch, as a pill, or as a free window.
nonisolated enum PrompterChrome: Equatable {
    case notch(height: CGFloat)
    case pill
    case floating

    /// Room left at the top for the camera housing.
    var topInset: CGFloat {
        if case .notch(let height) = self { height } else { 0 }
    }
}
