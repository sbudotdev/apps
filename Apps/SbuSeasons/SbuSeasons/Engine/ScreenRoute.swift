import CoreGraphics

/// Il percorso di un passaggio su più schermi, dai `frame` di `NSScreen` (spazio globale, come in Impostazioni → Schermi).
///
/// Regole (SBU-114):
/// - si attraversano tutti gli schermi, nell'ordine in cui stanno da sinistra a destra (o al contrario, se vola a sinistra);
///   gli schermi che si sovrappongono in orizzontale (uno sopra l'altro) sono una colonna, attraversata dall'alto in basso;
/// - si entra nel vicino alla stessa quota globale da cui si è usciti; se il vicino non la copre (schermi sfalsati),
///   si vola alla quota solita di quello schermo.
nonisolated enum ScreenRoute {
    /// Gli indici di `frames` nell'ordine in cui li attraversa chi vola verso `heading` (1 = destra, -1 = sinistra).
    /// Gli schermi che si sovrappongono in orizzontale (un MacBook sotto un monitor più largo, anche non centrato)
    /// sono una colonna: si attraversano dall'alto in basso.
    static func order(_ frames: [CGRect], heading: CGFloat) -> [Int] {
        var columns: [(maxX: CGFloat, screens: [Int])] = []
        for i in frames.indices.sorted(by: { frames[$0].minX < frames[$1].minX }) {
            if let last = columns.last, frames[i].minX < last.maxX {
                columns[columns.count - 1] = (max(last.maxX, frames[i].maxX), last.screens + [i])
            } else {
                columns.append((frames[i].maxX, [i]))
            }
        }
        if heading < 0 { columns.reverse() }
        return columns.flatMap { $0.screens.sorted { frames[$0].maxY > frames[$1].maxY } }
    }

    /// Come `order`, ma solo gli schermi con `live` vero: su uno fermo la scena non va avanti e chi ci entra resta lì.
    static func order(_ frames: [CGRect], heading: CGFloat, live: [Bool]) -> [Int] {
        let on = frames.indices.filter { live[$0] }
        return order(on.map { frames[$0] }, heading: heading).map { on[$0] }
    }

    /// La quota (locale allo schermo) a cui entra in `band` chi esce dal vicino alla quota globale `y`.
    /// `band` è la zona in cui si può volare, in coordinate globali; `margin` tiene la slitta tutta dentro.
    /// nil = lo schermo non copre quella quota.
    static func entry(_ y: CGFloat, into band: CGRect, margin: CGFloat) -> CGFloat? {
        guard band.minY + margin <= y, y <= band.maxY - margin else { return nil }
        return y - band.minY
    }
}
