import CoreGraphics

/// Il percorso di un passaggio su più schermi, dai `frame` di `NSScreen` (spazio globale, come in Impostazioni → Schermi).
///
/// Regole (SBU-114):
/// - si attraversano tutti gli schermi, nell'ordine in cui stanno da sinistra a destra (o al contrario, se vola a sinistra);
///   due schermi nella stessa colonna, uno sopra l'altro, si attraversano dall'alto in basso;
/// - si entra nel vicino alla stessa quota globale da cui si è usciti; se il vicino non la copre (schermi sfalsati),
///   si vola alla quota solita di quello schermo.
nonisolated enum ScreenRoute {
    /// Gli indici di `frames` nell'ordine in cui li attraversa chi vola verso `heading` (1 = destra, -1 = sinistra).
    static func order(_ frames: [CGRect], heading: CGFloat) -> [Int] {
        frames.indices.sorted { a, b in
            let (fa, fb) = (frames[a], frames[b])
            if fa.midX != fb.midX { return heading > 0 ? fa.midX < fb.midX : fa.midX > fb.midX }
            return fa.maxY > fb.maxY
        }
    }

    /// La quota (locale allo schermo) a cui entra in `band` chi esce dal vicino alla quota globale `y`.
    /// `band` è la zona in cui si può volare, in coordinate globali; `margin` tiene la slitta tutta dentro.
    /// nil = lo schermo non copre quella quota.
    static func entry(_ y: CGFloat, into band: CGRect, margin: CGFloat) -> CGFloat? {
        guard band.minY + margin <= y, y <= band.maxY - margin else { return nil }
        return y - band.minY
    }
}
