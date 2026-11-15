# CozySnow ❄︎

Neve che cade sopra tutte le finestre del Mac, **si accumula sul bordo superiore delle finestre**
e sul fondo dello schermo, e col cursore la sposti e la sparpagli.

Requisiti: macOS 14+, Xcode 26+, XcodeGen (`brew install xcodegen`).

## Provarla mentre la sviluppi

```bash
cd Apps/CozySnow
xcodegen                                   # genera CozySnow.xcodeproj da project.yml
xcodebuild test -scheme CozySnow -destination 'platform=macOS'
open CozySnow.xcodeproj                    # schema CozySnow, destinazione My Mac, ▶︎
```

Il progetto Xcode non è nella repo: si rigenera con `xcodegen` dopo ogni cambio a `project.yml` o ai file.

## Costruire l'app

```bash
xcodebuild -scheme CozySnow -configuration Release -derivedDataPath build build
open build/Build/Products/Release/CozySnow.app
```

Senza `SBU_TEAM_ID` la firma è "ad-hoc": va bene sul tuo Mac, ma macOS chiede di nuovo il permesso
Accessibilità dopo ogni build. Per darla ad altri servono la firma Developer ID e la notarizzazione,
oppure il Mac App Store: lo decide l'ADR-0022 (`docs/adr/0022-app-mac.md`).

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
| `Tuning.swift` | I parametri fissi (fisica, cursore, mucchi, lettura delle finestre) |
| `project.yml` | Progetto XcodeGen: target app (LSUIElement) e test |

I valori predefiniti sono in `SnowSettings` (`Settings.swift`); i parametri fissi in `Tuning.swift`.

## Prossimi passi possibili

- Palle di neve con ⌥ e pupazzo di neve
- Sfondo natalizio automatico (`NSWorkspace.shared.setDesktopImageURL`)
- Icona dell'app
