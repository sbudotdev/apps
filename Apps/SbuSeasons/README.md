# Sbu Seasons ❄︎

App Mac nella barra dei menu, pensata per più stagioni e temi; oggi c'è l'inverno, con la neve, e l'estate, con i semi di tarassaco.
Nasce da l'app di Simone Antoniciello, rinominata Sbu Seasons il 15/11/2026 (MGS-421).

Neve che cade sopra tutte le finestre del Mac, **si accumula sul bordo superiore delle finestre**
e sopra il Dock, e col cursore la sposti e la sparpagli.

**Permessi.** Nessuno per la neve e l'accumulo sulle finestre. Con il permesso Accessibilità
(Impostazioni di Sistema → Privacy e sicurezza) la neve si posa anche sul Dock e segue gli angoli
più stondati delle app con barra strumenti. Se il Dock si nasconde o sta di lato, sul fondo non si posa niente.
L'app non è nella sandbox: senza, macOS non darebbe né le finestre delle altre app né l'Accessibilità.

Sulle finestre attaccate alla barra dei menu (quelle ingrandite e le tante che si aprono in alto) la neve
si posa poco sotto, sulla barra del titolo, con la cima che tocca la barra dei menu: così non copre le voci di menu.
Sulle app a schermo intero non si posa niente.
A batteria va a 30 fotogrammi al secondo invece di 60, per consumare meno.

Requisiti: macOS 14+, Xcode 26+, XcodeGen (`brew install xcodegen`).

## Provarla mentre la sviluppi

```bash
cd Apps/SbuSeasons
xcodegen                                   # genera SbuSeasons.xcodeproj da project.yml
xcodebuild test -scheme SbuSeasons -destination 'platform=macOS'
open SbuSeasons.xcodeproj                  # schema SbuSeasons, destinazione My Mac, ▶︎
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

## Il .dmg da distribuire

```bash
./make-dmg.sh 1.3.1    # → build/dist/SbuSeasons-1.3.1.dmg
```

Build Release universale (arm64 + x86_64), firma Developer ID, `.dmg` con il collegamento ad Applicazioni,
notarizzazione e `stapler staple`; alla fine `spctl` deve dire `Notarized Developer ID`.
Usa `SBU_TEAM_ID` e la chiave API di App Store Connect di fastlane (`ASC_KEY_PATH`, `ASC_KEY_ID`, `ASC_ISSUER_ID`).
La 1.3 è nella [release della repo](https://github.com/sbudotdev/SbuSeasons/releases/tag/v1.3).

**1.3.1.** La 1.3 crashava all'avvio su un MacBook (la 1.2 partiva). La 1.3.1 toglie la novità della 1.3
(un display link per schermo con `SKRenderer`, MGS-636) e torna alla `SKView` della 1.2 (MGS-686).
Con due monitor a frequenze diverse (per esempio 144 e 60 Hz) la neve torna lenta su uno dei due:
la correzione dei due monitor si rifà in un ticket a parte.

**Dal vecchio nome.** Al primo avvio le impostazioni e "Fai nevicare" salvati con il nome di prima
si copiano da soli (`PreviousDefaults` in `Settings.swift`). Il permesso Accessibilità e "Apri al login"
sono legati al bundle id: con il nome nuovo vanno dati di nuovo.

## Menu ❄︎

Fai nevicare (⌘S) · Sciogli la neve (⌘R) · Stagione · Intensità (scorciatoie) · Impostazioni… (⌘,) · Esci (⌘Q).
Le scorciatoie funzionano a menu aperto: non sono globali.
La stagione scelta si salva (la neve è quella di partenza) e l'icona nella barra dei menu la segue.

**Impostazioni**: quantità, dimensione e velocità dei fiocchi, vento, raggio e forza del cursore,
accumulo sulle finestre e sul fondo, velocità di accumulo, altezza massima, apri al login, ripristino.
Le modifiche si vedono subito (nevica anche sulla finestra Impostazioni, utile per provare) e vengono salvate.

## Struttura

Il **motore** (`Engine/`) è comune a tutte le stagioni; ogni **stagione** (`Seasons/<Nome>/`) dice solo che cosa cade.

| File | Cosa fa |
|---|---|
| `App.swift` | Punto di ingresso, app senza icona nel Dock |
| `AppDelegate.swift` | Una finestra per schermo, menu ❄︎ (con Stagione), legge le finestre 8 volte al secondo |
| `Engine/Season.swift` | Il protocollo `Season` e `Particle`: ciò che una stagione deve dire al motore |
| `Engine/OverlayWindow.swift` | Finestra trasparente, sempre sopra, attraversata dai click |
| `Engine/SeasonScene.swift` | Fiocchi, vento, cursore, collisione coi mucchi, neve che cade quando muovi una finestra |
| `Engine/Pile.swift` | Un mucchio: altezze per colonna, frana, scavo col cursore, disegno |
| `Engine/Windows.swift` | Dove sono le finestre (`CGWindowListCopyWindowInfo`) e quali tratti dei bordi sono scoperti |
| `Seasons/Seasons.swift` | L'elenco delle stagioni, una riga ciascuna |
| `Seasons/Snow/Snow.swift` | La neve: forma, colore e caduta dei fiocchi (`SnowTuning`) |
| `Seasons/Summer/Summer.swift` | L'estate: semi di tarassaco, lenti e larghi nell'ondeggiare, si posano color panna (`SummerTuning`) |
| `PowerSource.swift` | Batteria o corrente (per i fotogrammi al secondo) |
| `Settings.swift` | Le impostazioni e la stagione (salvate in UserDefaults, copiate dal vecchio nome al primo avvio) e la finestra SwiftUI per regolarle |
| `Localizable.xcstrings`, `InfoPlist.xcstrings` | Le stringhe in italiano e inglese; il nome "Sbu Seasons" nel menu dell'app in alto |
| `Density.swift` | Le scorciatoie Leggera / Media / Forte del menu |
| `Tuning.swift` | I parametri fissi del motore (fisica, cursore, mucchi, lettura delle finestre) |
| `project.yml` | Progetto XcodeGen: target app (LSUIElement) e test |

I valori predefiniti sono in `SnowSettings` (`Settings.swift`); i parametri fissi in `Tuning.swift`.

## Aggiungere una stagione

1. Crea la cartella `SbuSeasons/Seasons/<Nome>/` con un file `<Nome>.swift` e un tipo che segue `Season`
   (copia `Snow.swift` come punto di partenza):
   - `id`: una parola in inglese minuscolo (`"leaves"`); si salva nelle impostazioni, quindi una volta uscita non cambia;
   - `title`: il nome nel menu, con `String(localized:)`, e la traduzione inglese in `Localizable.xcstrings`;
   - `symbol`: il simbolo SF per la barra dei menu e per il menu Stagione;
   - `pileColor`: il colore di ciò che si posa sulle finestre e sul Dock;
   - `makeTexture()`: la forma della particella, disegnata una volta;
   - `particle(depth:)`: raggio, opacità, velocità di caduta e oscillazione di una particella (0 = lontana, 1 = vicina).
2. Aggiungi una riga in `Seasons/Seasons.swift`, nell'ordine in cui la vuoi nel menu. Nient'altro da toccare nel codice.
   Attenzione: alcuni testi parlano ancora solo di neve («Fai nevicare», «Sciogli la neve», le sezioni «Nevicata»
   e «Neve posata» e «Quantità di fiocchi» nelle Impostazioni). Renderli generici è una decisione di Matteo,
   da prendere prima che esca la seconda stagione.
3. I colori e i numeri della stagione stanno nel suo file (un `enum <Nome>Tuning` come `SnowTuning`), non in
   `Design/tokens.json`: sono contenuto, non interfaccia, e li approva Matteo guardando lo screenshot.
4. `xcodegen`, poi `xcodebuild test -scheme SbuSeasons -destination 'platform=macOS'`, e misura la CPU con la neve
   come riferimento: una stagione non deve consumare di più.

Se a una stagione serve qualcosa che il motore non sa fare (ruotare le particelle, farle rimbalzare…),
si cambia `Season` e `SeasonScene` in un lavoro a parte, prima, perché tocca tutte le stagioni.

## Prossimi passi possibili

- Palle di neve con ⌥ e pupazzo di neve
- Sfondo natalizio automatico (`NSWorkspace.shared.setDesktopImageURL`)
- Icona dell'app
