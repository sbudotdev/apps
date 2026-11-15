# Le app Mac stanno in `Apps/`, come quelle iPhone

**Stato: Accettato** da Matteo il 15/11/2026 (MGS-416), con la distribuzione Developer ID + notarizzazione.

Il numero 0019 era già preso da un ADR sul branch di Sbu ZTL (e 0020, 0021 da ZTL e Social), quindi questo è 0022.

La prima app Mac è **Sbu Seasons**, nata dall'app di Simone Antoniciello: neve sopra tutte le finestre, nella barra dei menu. È pensata per più stagioni e temi; oggi c'è solo l'inverno. Matteo ha deciso il 15/11 (MGS-415) che entra in questa repo con XcodeGen, accanto alle app iPhone. Regole per lei e per le prossime app Mac:

- **Una cartella in `Apps/`, un `project.yml` XcodeGen**, come le app iPhone: `platform: macOS`, `bundleIdPrefix: dev.sbu`, target minimo macOS 14, Swift 6 con `MainActor` di default e strict concurrency completa, test logici con Swift Testing. Il progetto Xcode non si committa. Il nome della cartella e il bundle id restano provvisori finché Matteo non approva il nome dell'app; poi seguono le app iPhone (per Sbu Seasons, scelto da Matteo il 15/11: `Apps/SbuSeasons`, `dev.sbu.SbuSeasons`, MGS-421). Se il bundle id cambia, le impostazioni salvate si copiano dal vecchio dominio di UserDefaults, con un test.
- **Storia degli autori.** Un'app che nasce fuori dalla repo entra con `git subtree add`, così i commit e il nome di chi l'ha scritta restano in `git log Apps/<App>`. La repo d'origine resta com'è: archiviarla o no lo decide Matteo.
- **SbuKit è solo iOS e watchOS** (`platforms: [.iOS(.v17), .watchOS(.v10)]`). Un'app Mac oggi non lo usa. Portarlo su macOS (aggiungere la piattaforma al `Package.swift` e far compilare i componenti AppKit-compatibili) tocca tutte le app ed è un ticket a parte, che Matteo deve conoscere.
- **Token.** Anche un'app Mac prende colori, misure, durate e font da `Design/tokens.json` (Quaderno, ADR-0013). Finché SbuKit non è su macOS, i token arrivano solo così: estendere `Tools/sync_tokens.py` per generare i colori anche per un target Mac è un ticket a parte, come sopra. Il lavoro di design su Sbu Seasons (MGS-417) parte da questa scelta.
- **Regole di prodotto uguali alle app iPhone**: niente dipendenze di terze parti, analytics, rete, account. Le stringhe in italiano e inglese in `Localizable.xcstrings`.
- **Permessi di sistema.** Un'app Mac che legge le finestre degli altri (`CGWindowListCopyWindowInfo`) o usa l'API di Accessibilità non può stare nella sandbox; lo dichiara nel `project.yml` (`ENABLE_APP_SANDBOX: NO`) e nel README, con il motivo e cosa smette di funzionare senza il permesso.

## Distribuzione: Developer ID + notarizzazione (decisa)

| | Developer ID + notarizzazione | Mac App Store |
|---|---|---|
| Come arriva all'utente | `.dmg` o `.zip` scaricato da sbu.dev | App Store |
| Sandbox | non obbligatoria | obbligatoria |
| Sbu Seasons così com'è | funziona (Accessibilità e lista finestre fuori sandbox) | non passa: senza sandbox niente Store, con la sandbox niente neve sul Dock e angoli giusti delle finestre (Accessibilità di altre app). La lista delle finestre in sandbox resta da verificare |
| Revisione | nessuna, solo la notarizzazione automatica di Apple | App Review (una a settimana, come le app iPhone) |
| Aggiornamenti | a mano (nuovo download) o con un aggiornatore, cioè rete | dallo Store |
| Account | lo stesso Apple Developer Program del team | lo stesso |
| Strumenti | `xcodebuild archive` + `notarytool` (skill `asc-notarization`) | fastlane come le app iPhone |

Matteo ha scelto **Developer ID + notarizzazione, con il download da sbu.dev**: è la strada che non toglie funzioni. Il Mac App Store resta escluso finché un'app Mac non può stare nella sandbox. La pagina sul sito e il controllo degli aggiornamenti sono decisioni a parte (il secondo introdurrebbe una chiamata di rete). Nessuna firma, notarizzazione o pubblicazione parte senza l'ok di Matteo.

## Ancora aperti

- SbuKit su macOS e token per il Mac: due ticket a parte, da aprire quando il design di Sbu Seasons ne ha bisogno.
- Icona di Sbu Seasons.
