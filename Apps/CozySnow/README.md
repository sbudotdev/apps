# CozySnow ❄︎

Neve che cade sopra tutte le finestre del Mac, **si accumula sul bordo superiore delle finestre**
e sul fondo dello schermo, e col cursore la sposti e la sparpagli.

Requisiti: macOS 14+, Xcode o i Command Line Tools (`xcode-select --install`).

## Provarla mentre la sviluppi

```bash
cd CozySnow
swift run          # compila e avvia (Ctrl+C per chiudere)
swift test         # lancia i test
```

**Da Xcode**: `File → Open…` → scegli `Package.swift` → schema `CozySnow`, destinazione `My Mac` → ▶︎.

## Costruire la vera app (CozySnow.app)

```bash
./build-app.sh     # crea CozySnow.app nella cartella del progetto
open CozySnow.app
```

Per tenerla: trascina `CozySnow.app` in `/Applicazioni`, avviala da lì e in **Impostazioni…** attiva **Apri al login**.
La firma è "ad-hoc": va bene sul tuo Mac. Per darla ad altri servono un account Apple Developer,
la firma "Developer ID" e la notarizzazione (`xcrun notarytool`).

## Menu ❄︎

Fai nevicare (⌘S) · Sciogli la neve (⌘R) · Intensità (scorciatoie) · Impostazioni… (⌘,) · Esci (⌘Q).

**Impostazioni**: quantità, dimensione e velocità dei fiocchi, vento, raggio e forza del cursore,
accumulo sulle finestre e sul fondo, velocità di accumulo, altezza massima, apri al login, ripristino.
Le modifiche si vedono subito (nevica anche sulla finestra Impostazioni, utile per provare) e vengono salvate.

## Struttura

| File | Cosa fa |
|---|---|
| `App.swift` | Punto di ingresso, app senza icona nel Dock |
| `AppDelegate.swift` | Una finestra di neve per schermo, menu ❄︎, legge le finestre 8 volte al secondo |
| `SnowOverlayWindow.swift` | Finestra trasparente, sempre sopra, attraversata dai click |
| `SnowScene.swift` | Fiocchi, vento, cursore, collisione coi mucchi, neve che cade quando muovi una finestra |
| `SnowPile.swift` | Un mucchio di neve: altezze per colonna, frana, scavo col cursore, disegno |
| `Windows.swift` | Dove sono le finestre (`CGWindowListCopyWindowInfo`) e quali tratti dei bordi sono scoperti |
| `Settings.swift` | Le impostazioni (salvate in UserDefaults) e la finestra SwiftUI per regolarle |
| `Density.swift` | Le scorciatoie Leggera / Media / Forte del menu |
| `Info.plist`, `build-app.sh` | Impacchettamento come .app |

I valori predefiniti sono in `SnowSettings` (`Settings.swift`); i pochi parametri fissi in cima a `SnowScene.swift` e `SnowPile.swift`.

## Prossimi passi possibili

- Palle di neve con ⌥ e pupazzo di neve
- Sfondo natalizio automatico (`NSWorkspace.shared.setDesktopImageURL`)
- Icona dell'app
