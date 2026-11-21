# Sbu sul Mac: macOS 15, Mac App Store, SbuKit anche su Mac

**Stato: Accettato** nella sostanza da Matteo in SBU-167 (Sbu Prompter sul Mac App Store, con il telecomando iPhone nella v1); il testo si rilegge con la PR di SBU-168.

Il ticket chiedeva "ADR-0019", ma i numeri da 0019 a 0023 sono già presi su altri branch (ZTL, Social, Sbu Seasons), quindi questo è 0024. Completa ADR-0022 (le app Mac stanno in `Apps/`) e ne cambia due punti: SbuKit ora gira anche su macOS, e il Mac App Store non è più escluso per tutte le app Mac.

## Perché

Matteo ha scelto in SBU-167 che la prossima app sia **Sbu Prompter**: un teleprompter gratuito per Mac, con un telecomando sull'iPhone (spec in SBU-166). È la prima app Mac che usa il design system di Sbu per intero: il copione, il conto alla rovescia e il punto fermo vengono da SbuKit e dai token, come sulle app iPhone. Per questo SbuKit deve compilare su macOS.

## Le regole

- **macOS 15 o successivo** per le app Mac che usano SbuKit. `Package.swift` dichiara `platforms: [.iOS(.v17), .macOS(.v15), .watchOS(.v10)]`. Sbu Seasons resta su macOS 14 e non usa SbuKit (ADR-0022); se un giorno lo usa, sale a macOS 15.
- **Mac App Store** per le app Mac che stanno nella sandbox, come Sbu Prompter. Developer ID con notarizzazione e download da sbu.dev resta la strada per le app che nella sandbox perderebbero funzioni, come Sbu Seasons (ADR-0022). Si sceglie app per app, nell'ADR o nella spec dell'app.
- **Universal purchase**: quando un'app ha sia il Mac sia l'iPhone (Sbu Prompter e il suo telecomando), i due target hanno lo stesso bundle id e un solo record su App Store Connect. Il record lo crea Matteo, con approvazione.
- **Una review a settimana vale anche per il Mac**: un invio ad App Review è uno solo per settimana, che sia per iPhone, per Mac o per entrambi. Ogni invio passa da Matteo.
- **Regole di prodotto uguali alle app iPhone**: niente dipendenze di terze parti, analytics, account, rete esterna. La rete locale verso i propri dispositivi (il telecomando) segue ADR-0007.

## Cosa di SbuKit vale sul Mac

Compilano e si usano su macOS:

- **Tema e token**: `SbuTheme` (colori, misure, durate), `SbuAccent`, `SbuFont` (Bricolage Grotesque, IBM Plex Mono), `SbuMotion`, `SbuContrast`. I colorset generati da `Tools/sync_tokens.py` sono `universal` con la variante scura, quindi il Mac segue chiaro e scuro del sistema senza codice in più.
- **Cifra e carta**: `SbuFigure`, `SbuFullStop` e il suo controllo DEBUG, `SbuPaper` (reticolo), `SbuScreenTitle`, `SbuEmpty`, `SbuFigureCard` e `SbuFigureCardImage` (il PNG si scrive con `NSBitmapImageRep` dove manca `UIImage`), `SbuFigureShareLink`.
- **Controlli**: `SbuButton` e i suoi stili, `SbuToggleStyle`, `SbuCheckboxStyle`, `SbuRowMark`, `SbuListCard`, `SbuFlowLayout`, `SbuPromisePills`, le pagine di testo (`SbuPrivacyPage`, `SbuLicenseText`).
- **`SbuHaptic`** compila (è `SensoryFeedback`), ma sul Mac quasi tutti i Mac non hanno aptica: non è un segnale su cui contare.

Restano solo iPhone (dietro `#if os(iOS)`), e sul Mac servono equivalenti propri dell'app:

- **La shell**: `SbuAppShell`, `SbuTabShell`, `SbuSettingsView`, `SbuIconPicker`, `SbuLicensesView`, l'aspetto della barra di navigazione. Sul Mac le impostazioni sono la finestra `Settings` di SwiftUI e l'app vive nella barra dei menu o in una finestra; non c'è icona alternativa da scegliere (l'icona del Dock non si cambia dallo Store).
- **La Chiusura** (`SbuClosure`) e i suoni (`SbuSound`): legati alla vibrazione e all'audio dell'iPhone. Se un'app Mac ha bisogno di un momento di chiusura, lo si decide nella sua spec.
- **`SbuListRow`** e le anteprime di `SbuToolField`.

La regola per il codice nuovo: in SbuKit SwiftUI puro quando basta; `#if canImport(UIKit)` (o `os(iOS)`) solo dove serve un'API UIKit, con l'equivalente AppKit accanto se il componente ha senso sul Mac.

## Token

`Tools/sync_tokens.py` genera SwiftUI puro (`Color("…", bundle: .module)`) e colorset `universal`: lo stesso output compila su iOS, watchOS e macOS. Nessun generatore separato per il Mac. Ogni app Mac ha il suo `accent-<app>` e `accent-on-ink-<app>` come le altre; `accent-prompter` è il ciano scelto da Matteo in SBU-174 (`#02787d` chiaro, `#46c6cd` scuro, `#2bb3b9` nella Chiusura).

Il pannello di Sbu Prompter è sempre scuro (`.colorScheme(.dark)`), anche col Mac in chiaro: sta sotto o accanto al notch nero e deve fondersi con lui. È l'unica eccezione al tema del sistema sul Mac.

## Test

`xcodebuild test` di SbuKit gira su un simulatore iPhone **e** su `platform=macOS`; la CI li esegue entrambi. I test che leggono font, colori o immagini usano i tipi della piattaforma (`PlatformFont`, `PlatformColor`, `ImageRenderer.pointSize`), così la stessa suite vale per i due sistemi.

## Conseguenze

- Ogni modifica a SbuKit va provata anche su macOS: un `UIColor` o un `UIImage` scritto senza guardia rompe la build Mac.
- La pagina Mac sul sito, la scheda del Mac App Store e il record di App Store Connect sono passi separati, con l'approvazione di Matteo.
