import Foundation

extension Side {
    /// The pair as the person wearing the watch calls it.
    var name: LocalizedStringResource { self == .us ? "Noi" : "Loro" }
}
