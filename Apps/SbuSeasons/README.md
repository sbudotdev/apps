# Sbu Seasons ❄︎

App Mac nella barra dei menu, pensata per più stagioni e temi: neve, primavera, estate, autunno, pioggia sul vetro, temporale, nebbia, nuvole,
lucciole, stelle cadenti e sereno.
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
Con **Riduci movimento** di macOS (Accessibilità → Schermo) va anche lei a 30 fotogrammi, cade metà dei fiocchi,
senza vento, oscillazione né rotazione, e gli oggetti non si lanciano e non rimbalzano: cadono dritti.
L'impostazione si segue anche mentre l'app è aperta.

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
./make-dmg.sh 1.4    # → build/dist/SbuSeasons-1.4.dmg
```

Build Release universale (arm64 + x86_64), firma Developer ID, `.dmg` con il collegamento ad Applicazioni,
notarizzazione e `stapler staple`; alla fine `spctl` deve dire `Notarized Developer ID`.
Usa `SBU_TEAM_ID` e la chiave API di App Store Connect di fastlane (`ASC_KEY_PATH`, `ASC_KEY_ID`, `ASC_ISSUER_ID`).
La 1.3 è nella [release della repo](https://github.com/sbudotdev/SbuSeasons/releases/tag/v1.3).

**1.3.1.** La 1.3 crashava all'avvio su un MacBook (la 1.2 partiva). La 1.3.1 toglie la novità della 1.3
(un display link per schermo con `SKRenderer`, MGS-636) e torna alla `SKView` della 1.2 (MGS-686).
Con due monitor a frequenze diverse (per esempio 144 e 60 Hz) la neve torna lenta su uno dei due:
la correzione dei due monitor si rifà in un ticket a parte.

**1.4 (7).** La neve va alla stessa velocità su due monitor a frequenze diverse, senza toccare la `SKView` (SBU-19).
SpriteKit chiamava `update` solo sulla scena dello schermo più lento: sull'altro la neve si fermava,
o andava a metà velocità a batteria. Ora ogni finestra prende un display link dalla sua `SKView`,
che segue il suo schermo, e muove lei la scena (`SeasonScene.step(at:)`); la `SKView` disegna come nella 1.2.
Il test `TwoScreensTests` lo prova con uno schermo virtuale a una frequenza diversa da quello principale.

**2.0 (in corso, branch `app/seasons-2`).** Oggetti con cui giocare sopra le finestre, suoni, scuotere (SBU-49 è il motore,
gli oggetti veri arrivano nei ticket dopo). `MARKETING_VERSION` è già 2.0.

**Dal vecchio nome.** Al primo avvio le impostazioni e "Fai nevicare" salvati con il nome di prima
si copiano da soli (`PreviousDefaults` in `Settings.swift`). Il permesso Accessibilità e "Apri al login"
sono legati al bundle id: con il nome nuovo vanno dati di nuovo.

## Giocare con la neve (2.0)

- **Palle di neve.** Tieni premuto ⌥ e passa il cursore sulla neve posata: la neve raccolta sparisce dal bordo e,
  quando basta (`Tuning.snowballSnow`, circa 15 cm di finestra piena), sotto il cursore nasce una palla. Si prende
  e si lancia col mouse, rimbalza un po' e rotola lungo i bordi finché cade. Al massimo 12 sullo schermo: oltre
  sparisce la più vecchia. Solo d'inverno: cambiando stagione palle e pupazzi si sciolgono.
- **Pupazzo.** Tre palle ferme a meno di 40 pt l'una dall'altra diventano un pupazzo di neve. Una palla in mano non conta.
- **Neve che scivola via.** Se sposti piano una finestra la neve resta sopra e la segue; se la trascini veloce
  (più di 40 pt in un ottavo di secondo, circa 320 pt/s) o la ridimensioni, la neve scivola giù come polvere.
  La neve segue la finestra a scatti, 8 volte al secondo: tante sono le letture delle finestre.
- **Palla di vetro.** Scuoti il cursore o una finestra (o «Scuoti la palla di vetro» nel menu): tutta la neve posata
  si alza, i fiocchi salgono, le palle saltano, poi tutto ricade. Dopo una scossa riposa 3 s. Con Riduci movimento no.
  Mentre tieni ⌥ (d'inverno) il cursore non scuote: passare avanti e indietro sulla neve per raccoglierla non deve portarla via.
- Menu: «Togli le palle di neve» toglie le palle sciolte (i pupazzi restano); «Sciogli la neve» toglie anche palle e pupazzi.
- Suoni (se ci sono i file, SBU-56): `palla-di-neve`, `pupazzo`, `palla-di-vetro`.

## Pioggia, temporale, nebbia, nuvole (2.0)

- **Pioggia sul vetro.** Lo schermo è il vetro di una finestra: le gocce si posano a caso, quelle che si toccano
  si uniscono (le aree si sommano), e quando una è abbastanza grossa scorre giù, sempre più veloce quanto più è pesante,
  raccoglie le gocce che incontra e lascia dietro goccioline. Arrivata sul bordo scoperto di una finestra o sul Dock
  cade giù libera; in fondo allo schermo sparisce. Quando il vetro è pieno, la pioggia cade sulle gocce che ci sono.
- **Temporale.** Pioggia forte e obliqua (copre tutto lo schermo, anche il lato da cui viene), nuvole scure in cima,
  gocce sul vetro, e ogni 6–18 s un lampo lontano: due bagliori che illuminano le nuvole e il cielo dietro, poi,
  1,5–4 s dopo, il tuono (suono `tuono`, se c'è il file, SBU-56).
- **Nebbia.** Tre strati bassi e sfumati, uno sopra l'altro, che scorrono verso destra a velocità diverse.
- **Nuvole.** Banchi bianchi che attraversano piano la parte alta dello schermo; usciti a destra rientrano da sinistra.
- L'intensità (menu e "Quantità") cambia quante gocce cadono sul vetro e quanti banchi ci sono.
- Con **Riduci movimento**: niente lampi (è luce che lampeggia), banchi al 40% della velocità e la metà dei banchi,
  metà delle gocce nuove, che scorrono a metà velocità e senza zigzag.
- Niente si posa sulle finestre: scegliendo una di queste stagioni la neve posata si scioglie.

Il codice: `Toys/Snowball/Snowball.swift` (palla, pupazzo, quando tre palle fanno un pupazzo), e in `SeasonScene`
le sezioni «Palle di neve e pupazzo» e «Palla di vetro». La neve che segue la finestra è `Pile.carry`.

## Menu ❄︎

Fai nevicare (⌘S) · Sciogli la neve (⌘R) · Togli le palle di neve · Scuoti la palla di vetro · Stagione ·
Intensità (Leggera/Media/Forte con le scorciatoie, e sotto un cursore continuo) · Impostazioni… (⌘,) · Esci (⌘Q).
Il cursore è lo stesso valore di "Quantità di fiocchi" nelle Impostazioni: muovendolo le particelle in più nascono in cima
e quelle in meno spariscono, quelle che stanno cadendo non saltano.
Le scorciatoie funzionano a menu aperto: non sono globali.
La stagione scelta si salva (la neve è quella di partenza) e l'icona nella barra dei menu la segue.

**Impostazioni**: quantità, dimensione e velocità dei fiocchi, vento, raggio e forza del cursore,
accumulo sulle finestre e sul fondo, velocità di accumulo, altezza massima, suoni e volume (spenti all'inizio),
apri al login, ripristino.
Le modifiche si vedono subito (nevica anche sulla finestra Impostazioni, utile per provare) e vengono salvate.

## Struttura

Il **motore** (`Engine/`) è comune a tutte le stagioni; ogni **stagione** (`Seasons/<Nome>/`) dice solo che cosa cade.

| File | Cosa fa |
|---|---|
| `App.swift` | Punto di ingresso, app senza icona nel Dock |
| `AppDelegate.swift` | Una finestra per schermo, menu ❄︎ (con Stagione), legge le finestre 8 volte al secondo |
| `Engine/Season.swift` | Il protocollo `Season` e `Particle`: ciò che una stagione deve dire al motore |
| `Engine/OverlayWindow.swift` | Finestra trasparente, sempre sopra, attraversata dai click; il suo display link muove la scena |
| `Engine/SeasonScene.swift` | Fiocchi, vento, cursore, collisione coi mucchi, neve che cade quando muovi una finestra |
| `Engine/Pile.swift` | Un mucchio: altezze per colonna, frana, scavo col cursore, disegno |
| `Engine/Toy.swift`, `Engine/ToyBody.swift`, `Engine/Ledge.swift` | Gli oggetti con cui giocare: disegno, fisica (gravità, appoggio, lancio), i bordi su cui stanno |
| `Engine/ShakeDetector.swift`, `Engine/WindowShakes.swift`, `Engine/Shake.swift` | Cursore e finestre scossi |
| `Toys/Snowball/Snowball.swift` | Palla di neve (rotola), pupazzo, `snowmanTrio` |
| `Engine/Sky.swift` | Banchi a tutto schermo (nebbia, nuvole: pochi sprite grandi e sfumati) e lampi |
| `Engine/Glass.swift` | Gocce sul vetro: `GlassDrops` (logica, testata) e `Glass` (una sprite per goccia) |
| `Engine/SoundBoard.swift` | Effetti brevi e sottofondo in loop (`AVAudioPlayer`) |
| `Engine/Windows.swift` | Dove sono le finestre (`CGWindowListCopyWindowInfo`) e quali tratti dei bordi sono scoperti |
| `Seasons/Seasons.swift` | L'elenco delle stagioni, una riga ciascuna |
| `Seasons/Snow/Snow.swift` | La neve: forma, colore e caduta dei fiocchi (`SnowTuning`) |
| `Seasons/Summer/Summer.swift` | L'estate: semi di tarassaco, lenti e larghi nell'ondeggiare, si posano color panna (`SummerTuning`) |
| `Seasons/Spring/Spring.swift`, `Seasons/Autumn/Autumn.swift` | Petali di ciliegio portati dal vento e foglie d'autunno che volteggiano e si posano |
| `Seasons/Fireflies/Fireflies.swift` | Le lucciole: luci che vagano piano e si accendono e si spengono, non si posano (`FirefliesTuning`) |
| `Seasons/Meteors/Meteors.swift` | Le stelle cadenti: ogni tanto una scia attraversa il cielo di traverso (`MeteorsTuning`) |
| `Seasons/Rain/Rain.swift`, `Seasons/Storm/Storm.swift` | Pioggia sul vetro; temporale: pioggia obliqua, nuvole scure, lampi |
| `Seasons/Mist/Mist.swift`, `Seasons/Clouds/Clouds.swift` | Nebbia in strati bassi; nuvole in alto |
| `Seasons/Clear/Clear.swift` | Il sereno: non cade niente (per chi vuole solo gli oggetti o lo sfondo) |
| `PowerSource.swift` | Batteria o corrente (per i fotogrammi al secondo) |
| `Settings.swift` | Le impostazioni e la stagione (salvate in UserDefaults, copiate dal vecchio nome al primo avvio) e la finestra SwiftUI per regolarle |
| `Localizable.xcstrings`, `InfoPlist.xcstrings` | Le stringhe in italiano e inglese; il nome "Sbu Seasons" nel menu dell'app in alto |
| `Density.swift` | Le scorciatoie Leggera / Media / Forte del menu |
| `Tuning.swift` | I parametri fissi del motore (fisica, cursore, mucchi, lettura delle finestre) |
| `project.yml` | Progetto XcodeGen: target app (LSUIElement) e test |

I valori predefiniti sono in `SnowSettings` (`Settings.swift`); i parametri fissi in `Tuning.swift`.

## Clic sugli oggetti

La finestra della neve copre tutto lo schermo e sta sopra alle altre, ma i clic la attraversano
(`ignoresMouseEvents = true`): il Mac si usa come se non ci fosse. Per cliccare e trascinare un oggetto,
la finestra deve prendere il mouse **solo** sopra l'oggetto.

Come: a ogni fotogramma la scena legge già dove è il cursore (serve ai fiocchi). Con quella posizione guarda
se sotto c'è un oggetto, o se ne stai trascinando uno (`SeasonScene.wantsMouse`). Solo allora la finestra mette
`ignoresMouseEvents = false`; appena il cursore esce torna `true`. Il valore si cambia solo quando cambia: leggere
`ignoresMouseEvents` a ogni fotogramma costava CPU.

Perché così e non un monitor globale degli eventi (`NSEvent.addGlobalMonitorForEvents`): un monitor globale vede i clic
ma non li può fermare, quindi il clic arriverebbe anche all'app sotto l'oggetto; per fermarli servirebbe un event tap,
che chiede il permesso "Monitoraggio input". Così invece non serve nessun permesso e il clic va solo a uno dei due.

Dettagli:
- la finestra è un `NSPanel` "non attivante": cliccare un oggetto non porta Sbu Seasons davanti e non toglie la tastiera
  all'app che usi; la `SKView` accetta il primo clic (`acceptsFirstMouse`), se no il primo clic andrebbe perso;
- clic = pressione e rilascio a meno di 4 pt (`Tuning.clickSlop`): l'oggetto riceve `clicked()`; più lontano è un
  trascinamento, e al rilascio l'oggetto parte con la velocità del mouse (fermo da più di 0,1 s: cade dritto);
- limite: tra un fotogramma e l'altro (16 ms) il cursore può arrivare sull'oggetto e cliccare prima che la finestra
  prenda il mouse; in quel caso il clic va all'app sotto. Con un movimento normale non succede.

Provato sul Mac: il clic sull'oggetto arriva all'oggetto e l'app davanti resta davanti; il clic fuori dall'oggetto
arriva alla finestra sotto; il trascinamento e il lancio funzionano.

## Aggiungere un oggetto

1. Una sottoclasse di `Toy` nella cartella della sua funzione (per esempio `Toys/Snowball/`), con il suo `SKSpriteNode`
   (l'àncora è il centro in basso: `position` è dove poggiano i piedi).
2. Sovrascrivi quello che serve: `clicked()` (clic), `shaken(_:)` (`.pointer` o `.window(id)` scossi), `bounce`.
3. Aggiungilo con `SeasonScene.add(_:)` (dall'app: `OverlayWindow.add(_:)`). Il motore lo fa cadere e lo posa sui
   tratti scoperti dei bordi delle finestre, sul Dock o sul fondo dello schermo; se la finestra si sposta o si chiude, cade.
   Dove coprirebbe la barra dei menu (un oggetto più alto della neve, su una finestra attaccata alla barra) non si ferma e cade più giù.
4. I suoni: `SoundBoard.shared.play("nome")` per un effetto, `startAmbience("nome")` per il sottofondo.
   Il file `nome.caf` (o `.m4a`, `.wav`, `.aiff`, `.mp3`) va in `SbuSeasons/`; se manca, non suona e non succede niente.

Scuotere: il cursore va avanti e indietro 4 volte in 1 s, di almeno 40 pt (`ShakeDetector`); una finestra 3 volte
in 1,5 s (le finestre si leggono solo 8 volte al secondo). Chi continua a scuotere fa una scossa sola.

## Aggiungere una stagione

1. Crea la cartella `SbuSeasons/Seasons/<Nome>/` con un file `<Nome>.swift` e un tipo che segue `Season`
   (copia `Snow.swift` come punto di partenza):
   - `id`: una parola in inglese minuscolo (`"leaves"`); si salva nelle impostazioni, quindi una volta uscita non cambia;
   - `title`: il nome nel menu, con `String(localized:)`, e la traduzione inglese in `Localizable.xcstrings`;
   - `symbol`: il simbolo SF per la barra dei menu e per il menu Stagione;
   - `pileColor`: il colore di ciò che si posa sulle finestre e sul Dock;
   - `makeTexture()`: la forma della particella, disegnata una volta;
   - `particle(depth:)`: raggio, opacità, velocità di caduta e oscillazione di una particella (0 = lontana, 1 = vicina);
     se serve anche rotazione (`spin`, `flip`), colore (`tint`), andare di traverso orientata (`drift`, `length`),
     vagare in su e in giù (`bob`), accendersi e spegnersi (`pulse`), aspettare prima di ripassare (`gap`);
   - se non deve posarsi: `settles = false` (scegliendola, la neve posata si scioglie); se ne servono meno o nessuna:
     `abundance` (× "Quantità": 0,12 le lucciole, 0,01 le stelle, 0 il sereno);
   - se servono: `banks` (strati di nebbia o nuvole che scorrono, `Bank`), `lightning` (lampi, `Lightning`),
     `glass` (gocce sul vetro, `GlassRain`). Qualunque stagione li può usare, anche insieme alle particelle.
2. Aggiungi una riga in `Seasons/Seasons.swift`, nell'ordine in cui la vuoi nel menu. Nient'altro da toccare nel codice.
   Attenzione: alcuni testi parlano ancora solo di neve («Fai nevicare», «Sciogli la neve», le sezioni «Nevicata»
   e «Neve posata» e «Quantità di fiocchi» nelle Impostazioni). Renderli generici è una decisione di Matteo,
   da prendere prima che esca la seconda stagione.
3. I colori e i numeri della stagione stanno nel suo file (un `enum <Nome>Tuning` come `SnowTuning`), non in
   `Design/tokens.json`: sono contenuto, non interfaccia, e li approva Matteo guardando lo screenshot.
4. `xcodegen`, poi `xcodebuild test -scheme SbuSeasons -destination 'platform=macOS'`, e misura la CPU con la neve
   come riferimento: una stagione non deve consumare di più.

**CPU** (SBU-51, MacBook a corrente, intensità Media, media di 15 s con `ps`): neve 6,2%, autunno 6,6%, primavera 7–8%,
lucciole 5,1%, stelle cadenti 4,4%, sereno 1,7%. Il motore nuovo non cambia la neve (5,9–6,7% prima, 5,5–6,3% dopo).

**CPU della 2.0 meteo** (SBU-52, Mac a corrente, schermo 1920×1080, intensità Media, tempo di CPU su 20 s, media di 4 giri
alternati con la neve): neve 9,1%, temporale 9,5% (+4%), pioggia sul vetro 8,7%, nebbia 6,0%, nuvole 5,5%.
Le misure dello stesso effetto variano di ±1,5 punti da un giro all'altro: per confrontare, alterna sempre con la neve.

Se a una stagione serve qualcosa che il motore non sa fare (farle rimbalzare…),
si cambia `Season` e `SeasonScene` in un lavoro a parte, prima, perché tocca tutte le stagioni.

## Prossimi passi possibili

- Sfondo natalizio automatico (`NSWorkspace.shared.setDesktopImageURL`)
- Icona dell'app
