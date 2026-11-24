import AppKit
import SwiftUI

/// The notch and pill panels have no window frame: these strips along the bottom and the sides
/// resize them by dragging, and save the size in the settings. The sides move together, so the
/// panel stays centered under the camera.
struct PanelResizeHandles: View {
    let settings: PrompterSettings

    private enum Edge { case bottom, leading, trailing }
    private static let thickness: CGFloat = 6

    /// Where the drag started, in screen points (stable while the window grows under the pointer).
    @State private var start: (mouse: CGPoint, width: Double, height: Double)?

    var body: some View {
        ZStack {
            handle(.bottom)
                .frame(height: Self.thickness)
                .frame(maxHeight: .infinity, alignment: .bottom)
            handle(.leading)
                .frame(width: Self.thickness)
                .frame(maxWidth: .infinity, alignment: .leading)
            handle(.trailing)
                .frame(width: Self.thickness)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .accessibilityHidden(true) // the same sizes are sliders in Settings > Position
    }

    private func handle(_ edge: Edge) -> some View {
        Color.clear
            .contentShape(.rect)
            .pointerStyle(.frameResize(position: position(edge)))
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { _ in resize(edge) }
                    .onEnded { _ in start = nil }
            )
    }

    private func position(_ edge: Edge) -> FrameResizePosition {
        switch edge {
        case .bottom: .bottom
        case .leading: .leading
        case .trailing: .trailing
        }
    }

    private func resize(_ edge: Edge) {
        let mouse = NSEvent.mouseLocation
        if start == nil { start = (mouse, settings.width, settings.height) }
        guard let start else { return }
        switch edge {
        case .bottom:
            settings.height = clamp(start.height + start.mouse.y - mouse.y, PrompterSettings.heights)
        case .leading:
            settings.width = clamp(start.width + 2 * (start.mouse.x - mouse.x), PrompterSettings.widths)
        case .trailing:
            settings.width = clamp(start.width + 2 * (mouse.x - start.mouse.x), PrompterSettings.widths)
        }
    }

    private func clamp(_ value: Double, _ range: ClosedRange<Double>) -> Double {
        min(max(value.rounded(), range.lowerBound), range.upperBound)
    }
}
