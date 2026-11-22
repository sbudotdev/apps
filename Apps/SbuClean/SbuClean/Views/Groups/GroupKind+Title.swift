import SwiftUI

extension GroupKind {
    /// The kind's name on its card and as the title of its list.
    var title: LocalizedStringKey {
        switch self {
        case .duplicate: "Duplicati"
        case .similar: "Simili"
        case .videos: "Video simili"
        }
    }
}
