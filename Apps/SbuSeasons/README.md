# SbuSeasons ❄︎

Neve che cade sopra tutte le finestre del Mac e si scosta al passaggio del cursore.
Livello 1: niente accumulo sulle finestre (arriva dopo).

Requisiti: macOS 14+, Xcode o i Command Line Tools (`xcode-select --install`).

## Avvio

**Da terminale**

```bash
cd SbuSeasons
swift run
```

**Da Xcode**: `File → Open…` → scegli `Package.swift` → schema `SbuSeasons`, destinazione `My Mac` → ▶︎.

**Da IntelliJ / VS Code**: apri la cartella e usa `swift run` dal terminale integrato.

Compare un'icona ❄︎ nella barra dei menu: pausa (⌘S dal menu), intensità, esci (⌘Q).
Da terminale si chiude anche con `Ctrl+C`.

## Struttura

| File | Cosa fa |
|---|---|
| `App.swift` | Punto di ingresso, app senza icona nel Dock |
| `AppDelegate.swift` | Una finestra di neve per schermo + menu ❄︎ |
| `SnowOverlayWindow.swift` | Finestra trasparente, sempre sopra, attraversata dai click |
| `SnowScene.swift` | Fiocchi, vento, oscillazione, interazione col cursore |
| `Density.swift` | Leggera / Media / Forte |

I parametri da ritoccare (raggio del cursore, forza, vento…) sono in cima a `SnowScene.swift`.

## Prossimi passi

- Livello 2: accumulo sul bordo superiore delle finestre (`CGWindowListCopyWindowInfo`)
- Sfondo natalizio automatico (`NSWorkspace.shared.setDesktopImageURL`)
- Avvio al login (`SMAppService.mainApp`, serve impacchettarla come .app)
