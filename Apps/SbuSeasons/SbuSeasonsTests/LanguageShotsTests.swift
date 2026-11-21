import AppKit
import SwiftUI
import Testing
@testable import SbuSeasons

/// Le finestre nella lingua del test, per vedere i testi tagliati (SBU-199). Fuori schermo, spente di norma:
/// `TEST_RUNNER_SBU_SHOTS=/tmp/shots xcodebuild test -scheme SbuSeasons -destination 'platform=macOS' -testLanguage de -only-testing:SbuSeasonsTests/LanguageShotsTests`
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.environment["SBU_SHOTS"] != nil))
struct LanguageShotsTests {
    private let folder = URL(fileURLWithPath: ProcessInfo.processInfo.environment["SBU_SHOTS"] ?? NSTemporaryDirectory())
    private let language = Bundle.main.preferredLocalizations.first ?? "it"

    /// Le Impostazioni si scorrono: una foto per pagina, dall'alto in fondo.
    @Test func settings() throws {
        let host = host(SettingsView())
        let scroll = try #require(Self.scrollViews(in: host).max { $0.frame.height < $1.frame.height })
        let page = scroll.contentView.bounds.height
        let total = scroll.documentView?.frame.height ?? page
        // Un po' di sovrapposizione tra una pagina e l'altra; l'ultima arriva in fondo.
        let tops = Array(stride(from: 0, to: total - page, by: page - 40)) + [max(total - page, 0)]
        for (index, top) in tops.enumerated() {
            scroll.contentView.scroll(to: NSPoint(x: 0, y: top))
            scroll.reflectScrolledClipView(scroll.contentView)
            try write(host, as: "impostazioni-\(index + 1)")
        }
    }

    /// Il tour ha l'altezza fissa: ogni pagina, per vedere se il testo lungo ci sta.
    @Test(arguments: TourPage.allCases)
    func tour(_ page: TourPage) throws {
        try write(host(TourView(page: page)), as: "tour-\(page.rawValue + 1)")
    }

    @Test func gallery() throws {
        try write(host(GalleryView()), as: "sfondi")
    }

    private func host(_ view: some View) -> NSHostingView<some View> {
        let host = NSHostingView(rootView: view.environment(\.locale, Locale(identifier: language)))
        host.frame = CGRect(origin: .zero, size: host.fittingSize)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        return host
    }

    private static func scrollViews(in view: NSView) -> [NSScrollView] {
        view.subviews.flatMap { ($0 as? NSScrollView).map { [$0] } ?? [] + scrollViews(in: $0) }
    }

    private func write(_ host: NSView, as name: String) throws {
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: .now + 0.2)   // le righe del Form arrivano al giro dopo
        let rep = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: rep)
        let png = try #require(rep.representation(using: .png, properties: [:]))
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try png.write(to: folder.appending(path: "\(language)-\(name).png"))
    }
}
