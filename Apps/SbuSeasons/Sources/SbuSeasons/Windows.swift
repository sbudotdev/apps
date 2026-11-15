import AppKit

/// Il bordo superiore di una finestra, su cui la neve si può posare.
/// Coordinate Cocoa globali: origine in basso a sinistra dello schermo principale.
struct WindowEdge: Equatable {
    let id: CGWindowID
    let rect: CGRect
    /// Tratti (in x) del bordo superiore NON coperti da finestre più in primo piano.
    let visible: [ClosedRange<CGFloat>]
}

/// Quanto spazio sopra il bordo occupa la neve: una finestra davanti che arriva
/// fin lì copre anche il mucchio, quindi quel tratto non deve raccogliere neve.
let pileClearance: CGFloat = 16

/// Legge le finestre visibili dal sistema e calcola i loro bordi superiori.
/// Non serve nessun permesso: posizione e dimensioni sono pubbliche
/// (solo i titoli richiederebbero "Registrazione schermo").
func currentWindowEdges() -> [WindowEdge] {
    guard let primary = NSScreen.screens.first else { return [] }
    let primaryHeight = primary.frame.height

    let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
        as? [[String: Any]] ?? []

    // La lista arriva già ordinata dalla finestra più in primo piano alla più in fondo.
    let windows: [(CGWindowID, CGRect)] = list.compactMap { w in
        // Solo finestre "normali" (livello 0): esclude Dock, barra dei menu e le nostre finestre di neve.
        // La finestra Impostazioni invece è normale, quindi ci nevica sopra: comodo per provare i valori.
        guard (w[kCGWindowLayer as String] as? NSNumber)?.intValue == 0,
              ((w[kCGWindowAlpha as String] as? NSNumber)?.doubleValue ?? 1) > 0,
              let id = (w[kCGWindowNumber as String] as? NSNumber)?.uint32Value,
              let bounds = w[kCGWindowBounds as String] as? NSDictionary,
              let r = CGRect(dictionaryRepresentation: bounds as CFDictionary),
              r.width >= 40, r.height >= 40
        else { return nil }
        // CoreGraphics: origine in ALTO a sinistra. Cocoa: in BASSO a sinistra.
        return (id, CGRect(x: r.minX, y: primaryHeight - r.maxY, width: r.width, height: r.height))
    }
    return visibleTopEdges(windows)
}

/// Parte pura (testabile): dato l'elenco fronte→fondo, toglie da ogni bordo superiore
/// i tratti coperti dalle finestre che stanno davanti.
func visibleTopEdges(_ windows: [(id: CGWindowID, rect: CGRect)]) -> [WindowEdge] {
    windows.enumerated().map { index, window in
        let y = window.rect.maxY
        var visible = [window.rect.minX...window.rect.maxX]
        for front in windows[..<index] where front.rect.minY <= y + pileClearance && front.rect.maxY >= y {
            visible = visible.flatMap { subtract(front.rect.minX...front.rect.maxX, from: $0) }
        }
        return WindowEdge(id: window.id, rect: window.rect, visible: visible)
    }
}

/// `range` meno `cut`: zero, uno o due pezzi.
private func subtract(_ cut: ClosedRange<CGFloat>, from range: ClosedRange<CGFloat>) -> [ClosedRange<CGFloat>] {
    guard cut.overlaps(range) else { return [range] }
    var pieces: [ClosedRange<CGFloat>] = []
    if range.lowerBound < cut.lowerBound { pieces.append(range.lowerBound...cut.lowerBound) }
    if cut.upperBound < range.upperBound { pieces.append(cut.upperBound...range.upperBound) }
    return pieces
}

/// Raggio degli angoli delle finestre di macOS (circa: varia un po' da app ad app).
let windowCornerRadius: CGFloat = 20
/// Raggio degli angoli del Dock.
let dockCornerRadius: CGFloat = 24

/// Il rettangolo del Dock (coordinate Cocoa globali), letto con l'API di Accessibilità.
/// Il sistema non dà altrimenti la sua larghezza: la "finestra" del Dock copre tutto lo schermo.
/// Senza il permesso Accessibilità restituisce nil (e sul Dock non si posa neve).
func currentDockFrame() -> CGRect? {
    guard AXIsProcessTrusted(),
          let primary = NSScreen.screens.first,
          let dock = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.dock").first
    else { return nil }

    // Il Dock è un'app che contiene una "lista" (AXList): è la barra con le icone.
    let app = AXUIElementCreateApplication(dock.processIdentifier)
    var children: CFTypeRef?
    guard AXUIElementCopyAttributeValue(app, kAXChildrenAttribute as CFString, &children) == .success,
          let list = (children as? [AXUIElement])?.first(where: { attribute($0, kAXRoleAttribute) as? String == kAXListRole }),
          let positionValue = attribute(list, kAXPositionAttribute),
          let sizeValue = attribute(list, kAXSizeAttribute)
    else { return nil }

    var position = CGPoint.zero
    var size = CGSize.zero
    AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
    AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
    guard size.width > 0, size.height > 0 else { return nil }
    // Accessibilità: origine in ALTO a sinistra, come CoreGraphics.
    return CGRect(x: position.x, y: primary.frame.height - position.y - size.height, width: size.width, height: size.height)
}

private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success ? value : nil
}
