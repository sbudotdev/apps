# SbuSeasons ❄︎

Neve che cade sopra tutte le finestre del Mac, **si accumula sul bordo superiore delle finestre**
e sopra il Dock, e col cursore la sposti e la sparpagli.

**Permessi.** Nessuno per la neve e l'accumulo sulle finestre. Con il permesso Accessibilità
(Impostazioni di Sistema → Privacy e sicurezza) la neve si posa anche sul Dock e segue gli angoli
più stondati delle app con barra strumenti. Se il Dock si nasconde o sta di lato, sul fondo non si posa niente.
L'app non è nella sandbox: senza, macOS non darebbe né le finestre delle altre app né l'Accessibilità.

La neve non si posa sui bordi delle finestre attaccati alla barra dei menu (coprirebbe le voci di menu).
A batteria va a 30 fotogrammi al secondo invece di 60, per consumare meno.

Requisiti: macOS 14+, Xcode 26+, XcodeGen (`brew install xcodegen`).

## Provarla mentre la sviluppi

```bash
cd Apps/SbuSeasons
xcodegen                                   # genera SbuSeasons.xcodeproj da project.yml
xcodebuild test -scheme SbuSeasons -destination 'platform=macOS'
open SbuSeasons.xcodeproj                    # schema SbuSeasons, destinazione My Mac, ▶︎
```

Il progetto Xcode non è nella repo: si rigenera con `xcodegen` dopo ogni cambio a `project.yml` o ai file.

## Costruire l'app

```bash
xcodebuild -scheme SbuSeasons -configuration Release -derivedDataPath build build
open build/Build/Products/Release/SbuSeasons.app
```

Senza `SBU_TEAM_ID` la firma è "ad-hoc": va bene sul tuo Mac, ma macOS chiede di nuovo il permesso
Accessibilità dopo ogni build. Per darla ad altri servono la firma Developer ID e la notarizzazione,
con il download da sbu.dev (ADR-0022, `docs/adr/0022-app-mac.md`).

## Menu ❄︎

Fai nevicare (⌘S) · Sciogli la neve (⌘R) · Intensità (scorciatoie) · Impostazioni… (⌘,) · Esci (⌘Q).
Le scorciatoie funzionano a menu aperto: non sono globali.

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
| `PowerSource.swift` | Batteria o corrente (per i fotogrammi al secondo) |
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
