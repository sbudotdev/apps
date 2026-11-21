import Foundation
import Observation

/// Everything the user can tune, saved in UserDefaults.
@Observable
final class PrompterSettings {
    enum TextColor: String, CaseIterable, Identifiable {
        case ink, muted, accent
        var id: Self { self }
    }

    enum Layout: String, CaseIterable, Identifiable {
        case notch, floating
        var id: Self { self }
    }

    static let fontSizes: ClosedRange<Double> = 16...72
    static let widths: ClosedRange<Double> = 240...1000
    static let heights: ClosedRange<Double> = 80...480
    static let opacities: ClosedRange<Double> = 0.3...1

    @ObservationIgnored private let defaults: UserDefaults
    /// Called after any change, so the app model can apply it.
    @ObservationIgnored var onChange: () -> Void = {}

    var textColor: TextColor { didSet { save(textColor.rawValue, "textColor") } }
    var fontSize: Double { didSet { save(fontSize, "fontSize") } }
    var isMirrored: Bool { didSet { save(isMirrored, "isMirrored") } }
    var backgroundOpacity: Double { didSet { save(backgroundOpacity, "backgroundOpacity") } }
    var layout: Layout { didSet { save(layout.rawValue, "layout") } }
    var width: Double { didSet { save(width, "width") } }
    var height: Double { didSet { save(height, "height") } }
    var mode: PrompterController.Mode { didSet { save(mode.rawValue, "mode") } }
    var countdown: Int { didSet { save(countdown, "countdown") } }
    var speed: Double { didSet { save(speed, "speed") } }
    /// Speech recognition locale, for example "it-IT".
    var voiceLocale: String { didSet { save(voiceLocale, "voiceLocale") } }
    var shortcuts: [ShortcutAction: KeyCombo] {
        didSet { save(try? JSONEncoder().encode(shortcuts), "shortcuts") }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        textColor = defaults.string(forKey: "textColor").flatMap(TextColor.init) ?? .ink
        fontSize = Self.double(defaults, "fontSize", default: 28)
        isMirrored = defaults.bool(forKey: "isMirrored")
        backgroundOpacity = Self.double(defaults, "backgroundOpacity", default: 1)
        layout = defaults.string(forKey: "layout").flatMap(Layout.init) ?? .notch
        width = Self.double(defaults, "width", default: 460)
        height = Self.double(defaults, "height", default: 160)
        mode = defaults.string(forKey: "mode").flatMap(PrompterController.Mode.init) ?? .fixed
        countdown = Int(Self.double(defaults, "countdown", default: 3))
        speed = Self.double(defaults, "speed", default: 40)
        voiceLocale = defaults.string(forKey: "voiceLocale")
            ?? (Locale.current.language.languageCode == .italian ? "it-IT" : "en-US")
        let saved = defaults.data(forKey: "shortcuts").flatMap { try? JSONDecoder().decode([ShortcutAction: KeyCombo].self, from: $0) }
        shortcuts = saved ?? Dictionary(uniqueKeysWithValues: ShortcutAction.allCases.map { ($0, $0.defaultCombo) })
    }

    /// `double(forKey:)` also reads launch arguments, which arrive as strings.
    private static func double(_ defaults: UserDefaults, _ key: String, default value: Double) -> Double {
        defaults.object(forKey: key) == nil ? value : defaults.double(forKey: key)
    }

    func combo(for action: ShortcutAction) -> KeyCombo {
        shortcuts[action] ?? action.defaultCombo
    }

    private func save(_ value: Any?, _ key: String) {
        defaults.set(value, forKey: key)
        onChange()
    }
}
