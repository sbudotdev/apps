#if canImport(UIKit)
import UIKit

/// The platform font and color, so the same tests run on iOS and macOS.
typealias PlatformFont = UIFont
typealias PlatformColor = UIColor
#else
import AppKit

/// The platform font and color, so the same tests run on iOS and macOS.
typealias PlatformFont = NSFont
typealias PlatformColor = NSColor
#endif

import SwiftUI

extension ImageRenderer {
    /// The rendered image's size in points, on any platform (`uiImage` is iOS only).
    var pointSize: CGSize? {
        cgImage.map { CGSize(width: CGFloat($0.width) / scale, height: CGFloat($0.height) / scale) }
    }
}
