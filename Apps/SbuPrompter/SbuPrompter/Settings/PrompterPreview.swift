import SbuKit
import SwiftUI

/// The prompter as it is now, scaled down in the settings: every change to colour, size,
/// opacity, mirroring and position shows here at once, and it moves with the real one.
struct PrompterPreview: View {
    @Environment(AppModel.self) private var model

    private static let maxWidth: CGFloat = 420
    private static let maxHeight: CGFloat = 140

    var body: some View {
        let settings = model.settings
        let size = panelSize
        let scale = min(Self.maxWidth / size.width, Self.maxHeight / size.height, 1)
        PrompterView(controller: model.controller, settings: settings, speech: model.speech, chrome: chrome,
                     isEmpty: model.controller.script.words.isEmpty, reportsLayout: false)
            .frame(width: size.width, height: size.height)
            .scaleEffect(scale, anchor: .topLeading)
            .frame(width: size.width * scale, height: size.height * scale, alignment: .topLeading)
            .allowsHitTesting(false)
            .frame(maxWidth: .infinity)
            .accessibilityElement()
            .accessibilityLabel(Text("Anteprima del prompter"))
    }

    private var panelSize: CGSize {
        model.settings.layout == .floating
            ? CGSize(width: 520, height: 240)
            : CGSize(width: model.settings.width, height: model.settings.height)
    }

    private var chrome: PrompterChrome {
        if model.settings.layout == .floating { return .floating }
        guard let screen = NSScreen.screens.first(where: { $0.safeAreaInsets.top > 0 }) else { return .pill }
        let notchWidth = screen.frame.width - (screen.auxiliaryTopLeftArea?.width ?? 0) - (screen.auxiliaryTopRightArea?.width ?? 0)
        return .notch(height: screen.safeAreaInsets.top, width: notchWidth)
    }
}
