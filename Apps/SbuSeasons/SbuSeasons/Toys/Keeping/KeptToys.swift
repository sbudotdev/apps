import CoreGraphics

/// Alberi (con le decorazioni) e pupazzi salvati, ognuno con il suo schermo (`NSScreen.wallpaperKey`) e i piedi
/// in coordinate di quello schermo. Le palle sciolte, gli slittini e il resto no: si rifanno in un attimo.
nonisolated struct KeptToys: Codable, Equatable, Sendable {
    struct Tree: Codable, Equatable, Sendable {
        var screen: String
        var position: CGPoint
        var look: TreeLook
    }

    struct Snowman: Codable, Equatable, Sendable {
        var screen: String
        var position: CGPoint
        var look: SnowmanLook
    }

    var trees: [Tree] = []
    var snowmen: [Snowman] = []

    /// Quale di `screens` prende un oggetto salvato su `screen`: lo stesso, o il primo (il principale) se non c'è più.
    static func screenIndex(for screen: String, among screens: [String]) -> Int {
        screens.firstIndex(of: screen) ?? 0
    }

    /// Solo gli oggetti degli schermi per cui `keep` dice sì.
    func only(_ keep: (String) -> Bool) -> KeptToys {
        KeptToys(trees: trees.filter { keep($0.screen) }, snowmen: snowmen.filter { keep($0.screen) })
    }

    static func + (a: KeptToys, b: KeptToys) -> KeptToys {
        KeptToys(trees: a.trees + b.trees, snowmen: a.snowmen + b.snowmen)
    }
}

extension KeptToys {
    /// Ogni scena (con il suo schermo) prende i suoi oggetti; quelli di schermi scollegati vanno sulla prima.
    @MainActor
    func restore(into scenes: [(screen: String, scene: SeasonScene)]) {
        let screens = scenes.map(\.screen)
        for (i, entry) in scenes.enumerated() {
            entry.scene.restore(only { Self.screenIndex(for: $0, among: screens) == i })
        }
    }
}
