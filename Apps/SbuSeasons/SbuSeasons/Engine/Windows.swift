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
    let all: [AppWindow] = list.compactMap { w in
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
        let rect = CGRect(x: r.minX, y: primaryHeight - r.maxY, width: r.width, height: r.height)
        let info = accessibilityInfo(of: id, pid: pid, rect: rect, primaryHeight: primaryHeight)
        return AppWindow(id: id, rect: rect, pid: pid, standard: info?.standard, toolbar: info?.toolbar ?? false)
    }
    let alive = Set(all.map(\.id))
    axCache = axCache.filter { alive.contains($0.key) }   // dimentica le finestre chiuse
    let settings = Settings.shared.values
    return systemEdges(all, clearance: CGFloat(settings.maxPile)).map { edge, window in
        var edge = edge
        // Su macOS 26 le app native con barra degli strumenti (Finder, Safari…) hanno angoli più stondati
        // delle altre (IntelliJ, Chrome…). I due valori si regolano nelle Impostazioni.
        edge.cornerRadius = CGFloat(window.toolbar ? settings.toolbarCornerRadius : settings.windowCornerRadius)
        return edge
    }
}

// MARK: - Solo finestre vere

/// Una finestra di livello 0 di un'app. `standard`: la risposta dell'Accessibilità
/// (subrole `AXStandardWindow`), nil se non c'è il permesso o l'app non la dà.
nonisolated struct AppWindow {
    let id: CGWindowID
    let rect: CGRect
    let pid: pid_t
    let standard: Bool?
    var toolbar = false
}

/// Parte pura (testabile): tiene solo le finestre vere di macOS, non i pannelli e le modali
/// che le app disegnano come finestre a sé (la ricerca di IntelliJ, palette, popover…), SBU-101.
/// - Con l'Accessibilità decide la subrole: resta solo `AXStandardWindow` (via dialoghi, pannelli, sheet).
/// - Senza risposta: è una modale se sta tutta dentro un'altra finestra più grande della stessa app.
/// Nessuna eccezione per singole app: non sappiamo come sono fatte dentro.
nonisolated func systemWindows(_ windows: [AppWindow]) -> [AppWindow] {
    windows.filter { window in
        if let standard = window.standard { return standard }
        return !windows.contains { other in
            other.id != window.id && other.pid == window.pid && other.rect.contains(window.rect)
                && other.rect.width * other.rect.height > window.rect.width * window.rect.height
        }
    }
}

/// I bordi delle sole finestre vere. Le coperture si calcolano su tutte le finestre: una modale scartata
/// non prende neve, ma il tratto di bordo che ha davanti resta coperto (se no la neve le finirebbe sopra).
nonisolated func systemEdges(_ windows: [AppWindow], clearance: CGFloat) -> [(edge: WindowEdge, window: AppWindow)] {
    let real = Set(systemWindows(windows).map(\.id))
    return zip(visibleTopEdges(windows.map { ($0.id, $0.rect) }, clearance: clearance), windows)
        .filter { real.contains($0.1.id) }
        .map { (edge: $0.0, window: $0.1) }
}

/// Quello che l'Accessibilità dice di una finestra.
private struct AccessibilityInfo { let standard: Bool; let toolbar: Bool }

/// Risposte già trovate, per ID di finestra (chiedere all'Accessibilità a ogni giro costerebbe troppo).
/// `tries` conta i tentativi falliti: una finestra appena aperta può non essere ancora visibile all'API.
private var axCache: [CGWindowID: (info: AccessibilityInfo?, tries: Int)] = [:]

/// nil = non lo sappiamo (niente permesso, o l'app non risponde): vale la regola senza permesso.
private func accessibilityInfo(of id: CGWindowID, pid: pid_t, rect: CGRect, primaryHeight: CGFloat) -> AccessibilityInfo? {
    if let cached = axCache[id], cached.info != nil || cached.tries >= 5 { return cached.info }
    // Senza permesso non è un tentativo: quando arriva, le finestre già aperte vanno ancora chieste.
    guard AXIsProcessTrusted() else { return nil }
    let tries = (axCache[id]?.tries ?? 0) + 1
    let found = askAccessibility(pid: pid, rect: rect, primaryHeight: primaryHeight)
    // Trovata la risposta, o dopo 5 tentativi a vuoto: la teniamo per sempre (per questa finestra).
    axCache[id] = (found, tries)
    return found
}

/// Chiede all'app `pid` com'è fatta la sua finestra in `rect`: subrole e barra degli strumenti.
/// nil = finestra non trovata (o l'app non risponde).
private func askAccessibility(pid: pid_t, rect: CGRect, primaryHeight: CGFloat) -> AccessibilityInfo? {
    let app = AXUIElementCreateApplication(pid)
    AXUIElementSetMessagingTimeout(app, 0.05)   // un'app bloccata non deve congelare la neve
    guard let windows = attribute(app, kAXWindowsAttribute) as? [AXUIElement] else { return nil }
    // Accessibilità usa l'origine in ALTO a sinistra: riconvertiamo il rettangolo per confrontarlo.
    let target = CGRect(x: rect.minX, y: primaryHeight - rect.maxY, width: rect.width, height: rect.height)
    for window in windows {
        guard let frame = frame(of: window),
              abs(frame.minX - target.minX) < 2, abs(frame.minY - target.minY) < 2,
              abs(frame.width - target.width) < 2, abs(frame.height - target.height) < 2 else { continue }
        let children = attribute(window, kAXChildrenAttribute) as? [AXUIElement] ?? []
        return AccessibilityInfo(
            standard: attribute(window, kAXSubroleAttribute) as? String == kAXStandardWindowSubrole,
            toolbar: children.contains { attribute($0, kAXRoleAttribute) as? String == kAXToolbarRole })
    }
    return nil
}

/// Parte pura (testabile): dato l'elenco fronte→fondo, toglie da ogni bordo superiore
/// i tratti coperti dalle finestre che stanno davanti.
/// `clearance`: quanto spazio sopra il bordo occupa la neve (l'altezza massima del mucchio):
/// una finestra davanti che arriva fin lì coprirebbe il mucchio, quindi quel tratto non raccoglie neve.
/// Anche una finestra davanti che sta sopra l'area di questa toglie il suo tratto: il fiocco va al bordo
/// della finestra più in primo piano, se no una finestra ingrandita dietro prende tutta la neve in cima (MGS-628).
nonisolated func visibleTopEdges(_ windows: [(id: CGWindowID, rect: CGRect)], clearance: CGFloat) -> [WindowEdge] {
    windows.enumerated().map { index, window in
        let y = window.rect.maxY
        var visible = [window.rect.minX...window.rect.maxX]
        for front in windows[..<index] where front.rect.minY <= y + clearance && front.rect.maxY >= window.rect.minY {
            visible = visible.flatMap { subtract(front.rect.minX...front.rect.maxX, from: $0) }
        }
        return WindowEdge(id: window.id, rect: window.rect, visible: visible)
    }
}

/// Dove poggia la neve di un bordo alto `edgeTop`, sotto `ceiling` (il limite della zona libera
/// dello schermo, sotto la barra dei menu). La neve sta sempre sul bordo, mai sotto (SBU-101).
/// nil se il mucchio entrerebbe nella barra dei menu (finestre ingrandite o attaccate alla barra,
/// app a schermo intero): quel bordo non prende neve e i fiocchi cadono più giù.
nonisolated func pileBase(edgeTop: CGFloat, pileHeight: CGFloat, ceiling: CGFloat) -> CGFloat? {
    edgeTop + pileHeight > ceiling + 1 ? nil : edgeTop   // +1: arrotondamenti dello schermo
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
    AXUIElementSetMessagingTimeout(app, 0.05)   // un Dock bloccato non deve congelare la neve
    guard let list = (attribute(app, kAXChildrenAttribute) as? [AXUIElement])?
              .first(where: { attribute($0, kAXRoleAttribute) as? String == kAXListRole }),
          let frame = frame(of: list), frame.width > 0, frame.height > 0
    else { return nil }
    // Accessibilità: origine in ALTO a sinistra, come CoreGraphics.
    return CGRect(x: frame.minX, y: primary.frame.height - frame.maxY, width: frame.width, height: frame.height)
}

/// Posizione e dimensione di un elemento (coordinate di Accessibilità, origine in alto a sinistra).
/// nil se l'app non le dà, o le dà di un tipo inatteso.
private func frame(of element: AXUIElement) -> CGRect? {
    guard let p = attribute(element, kAXPositionAttribute), CFGetTypeID(p) == AXValueGetTypeID(),
          let s = attribute(element, kAXSizeAttribute), CFGetTypeID(s) == AXValueGetTypeID()
    else { return nil }
    var position = CGPoint.zero, size = CGSize.zero
    guard AXValueGetValue(p as! AXValue, .cgPoint, &position),   // tipo controllato sopra
          AXValueGetValue(s as! AXValue, .cgSize, &size) else { return nil }
    return CGRect(origin: position, size: size)
}

private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
    var value: CFTypeRef?
    return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success ? value : nil
}
