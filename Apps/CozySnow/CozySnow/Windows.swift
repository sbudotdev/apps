import AppKit

/// Il bordo superiore di una finestra, su cui la neve si può posare.
/// Coordinate Cocoa globali: origine in basso a sinistra dello schermo principale.
nonisolated struct WindowEdge: Equatable {
    let id: CGWindowID
    let rect: CGRect
    /// Tratti (in x) del bordo superiore NON coperti da finestre più in primo piano.
    let visible: [ClosedRange<CGFloat>]
    /// Raggio degli angoli superiori della finestra.
    var cornerRadius: CGFloat = 20
}

/// Legge le finestre visibili dal sistema e calcola i loro bordi superiori.
/// Non serve nessun permesso: posizione e dimensioni sono pubbliche
/// (solo i titoli richiederebbero "Registrazione schermo").
func currentWindowEdges() -> [WindowEdge] {
    guard let primary = NSScreen.screens.first else { return [] }
    let primaryHeight = primary.frame.height

    let list = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
        as? [[String: Any]] ?? []

    // La lista arriva già ordinata dalla finestra più in primo piano alla più in fondo.
    let windows: [(id: CGWindowID, rect: CGRect, pid: pid_t)] = list.compactMap { w in
        // Solo finestre "normali" (livello 0): esclude Dock, barra dei menu e le nostre finestre di neve.
        // La finestra Impostazioni invece è normale, quindi ci nevica sopra: comodo per provare i valori.
        guard (w[kCGWindowLayer as String] as? NSNumber)?.intValue == 0,
              ((w[kCGWindowAlpha as String] as? NSNumber)?.doubleValue ?? 1) > 0,
              let id = (w[kCGWindowNumber as String] as? NSNumber)?.uint32Value,
              let pid = (w[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value,
              let bounds = w[kCGWindowBounds as String] as? NSDictionary,
              let r = CGRect(dictionaryRepresentation: bounds as CFDictionary),
              r.width >= 40, r.height >= 40
        else { return nil }
        // CoreGraphics: origine in ALTO a sinistra. Cocoa: in BASSO a sinistra.
        return (id, CGRect(x: r.minX, y: primaryHeight - r.maxY, width: r.width, height: r.height), pid)
    }
    let alive = Set(windows.map(\.id))
    radiusCache = radiusCache.filter { alive.contains($0.key) }   // dimentica le finestre chiuse
    return zip(visibleTopEdges(windows.map { ($0.id, $0.rect) }, clearance: CGFloat(Settings.shared.values.maxPile)), windows).map { edge, window in
        var edge = edge
        edge.cornerRadius = cornerRadius(of: window.id, pid: window.pid, rect: window.rect, primaryHeight: primaryHeight)
        return edge
    }
}

// MARK: - Angoli stondati

/// Raggio degli angoli: su macOS 26 le app native con barra degli strumenti (Finder, Safari…)
/// hanno angoli più stondati delle altre (IntelliJ, Chrome…). I due valori si regolano nelle Impostazioni.
private func cornerRadius(of id: CGWindowID, pid: pid_t, rect: CGRect, primaryHeight: CGFloat) -> CGFloat {
    let settings = Settings.shared.values
    let toolbar = toolbarInfo(of: id, pid: pid, rect: rect, primaryHeight: primaryHeight)
    return CGFloat(toolbar ? settings.toolbarCornerRadius : settings.windowCornerRadius)
}

/// Risposte già trovate, per ID di finestra (chiedere all'Accessibilità a ogni giro costerebbe troppo).
/// `tries` conta i tentativi falliti: una finestra appena aperta può non essere ancora visibile all'API.
private var radiusCache: [CGWindowID: (toolbar: Bool?, tries: Int)] = [:]

private func toolbarInfo(of id: CGWindowID, pid: pid_t, rect: CGRect, primaryHeight: CGFloat) -> Bool {
    if let known = radiusCache[id]?.toolbar { return known }
    let tries = (radiusCache[id]?.tries ?? 0) + 1
    let found = AXIsProcessTrusted() ? hasToolbar(pid: pid, rect: rect, primaryHeight: primaryHeight) : nil
    // Trovata la risposta, o dopo 5 tentativi a vuoto: la teniamo per sempre (per questa finestra).
    radiusCache[id] = (found ?? (tries >= 5 ? false : nil), tries)
    return found ?? false
}

/// Chiede all'app `pid` se la sua finestra in `rect` ha una barra degli strumenti.
/// nil = finestra non trovata (o l'app non risponde).
private func hasToolbar(pid: pid_t, rect: CGRect, primaryHeight: CGFloat) -> Bool? {
    let app = AXUIElementCreateApplication(pid)
    AXUIElementSetMessagingTimeout(app, 0.05)   // un'app bloccata non deve congelare la neve
    guard let windows = attribute(app, kAXWindowsAttribute) as? [AXUIElement] else { return nil }
    // Accessibilità usa l'origine in ALTO a sinistra: riconvertiamo il rettangolo per confrontarlo.
    let target = CGRect(x: rect.minX, y: primaryHeight - rect.maxY, width: rect.width, height: rect.height)
    for window in windows {
        var position = CGPoint.zero, size = CGSize.zero
        guard let p = attribute(window, kAXPositionAttribute), let s = attribute(window, kAXSizeAttribute) else { continue }
        AXValueGetValue(p as! AXValue, .cgPoint, &position)
        AXValueGetValue(s as! AXValue, .cgSize, &size)
        guard abs(position.x - target.minX) < 2, abs(position.y - target.minY) < 2,
              abs(size.width - target.width) < 2, abs(size.height - target.height) < 2 else { continue }
        let children = attribute(window, kAXChildrenAttribute) as? [AXUIElement] ?? []
        return children.contains { attribute($0, kAXRoleAttribute) as? String == kAXToolbarRole }
    }
    return nil
}

/// Parte pura (testabile): dato l'elenco fronte→fondo, toglie da ogni bordo superiore
/// i tratti coperti dalle finestre che stanno davanti.
/// `clearance`: quanto spazio sopra il bordo occupa la neve (l'altezza massima del mucchio):
/// una finestra davanti che arriva fin lì coprirebbe il mucchio, quindi quel tratto non raccoglie neve.
nonisolated func visibleTopEdges(_ windows: [(id: CGWindowID, rect: CGRect)], clearance: CGFloat) -> [WindowEdge] {
    windows.enumerated().map { index, window in
        let y = window.rect.maxY
        var visible = [window.rect.minX...window.rect.maxX]
        for front in windows[..<index] where front.rect.minY <= y + clearance && front.rect.maxY >= y {
            visible = visible.flatMap { subtract(front.rect.minX...front.rect.maxX, from: $0) }
        }
        return WindowEdge(id: window.id, rect: window.rect, visible: visible)
    }
}

/// `range` meno `cut`: zero, uno o due pezzi.
nonisolated private func subtract(_ cut: ClosedRange<CGFloat>, from range: ClosedRange<CGFloat>) -> [ClosedRange<CGFloat>] {
    guard cut.overlaps(range) else { return [range] }
    var pieces: [ClosedRange<CGFloat>] = []
    if range.lowerBound < cut.lowerBound { pieces.append(range.lowerBound...cut.lowerBound) }
    if cut.upperBound < range.upperBound { pieces.append(cut.upperBound...range.upperBound) }
    return pieces
}

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
