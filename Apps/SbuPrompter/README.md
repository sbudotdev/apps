# Sbu Prompter (Mac)

Teleprompter gratuito per Mac: il copione scorre nel notch, sotto la fotocamera, e non compare quando condividi lo schermo, nelle registrazioni o negli screenshot. Spec: SBU-166, ADR-0024 per SbuKit sul Mac.

Il telecomando iPhone (`SbuPrompterRemote`, iOS 17) è la stessa app: stesso bundle id, universal purchase. Parla col Mac solo in rete locale, con MultipeerConnectivity cifrato (ADR-0007).

```sh
xcodegen generate
xcodebuild test -project SbuPrompter.xcodeproj -scheme SbuPrompter -destination platform=macOS
xcodebuild test -project SbuPrompter.xcodeproj -scheme SbuPrompterRemote -destination 'platform=iOS Simulator,name=<iPhone>'
```

Prova vera col Mac: avvia la build Debug del Mac, leggi il codice dal menu (o con `kill -USR1 <pid>`, campo `remoteCode`) e lancia il test UI con quel codice. Senza codice il test viene saltato.

```sh
TEST_RUNNER_SBU_PROMPTER_CODE=1234 TEST_RUNNER_SBU_PROMPTER_SHOTS=/tmp/prompter-shots \
  xcodebuild test -project SbuPrompter.xcodeproj -scheme SbuPrompterRemote \
  -destination 'platform=iOS Simulator,name=<iPhone>' -only-testing:SbuPrompterRemoteUITests
```

Deve girare un solo Sbu Prompter sul Mac: due copie si annunciano con lo stesso nome, l'iPhone le mostra come «Mac (2)» e il test non sa quale scegliere. Con Xcode 27 `xcodebuild` a volte resta appeso dopo "Test Suite 'All tests' passed": il risultato è già nel log, e gli screenshot sono nella cartella di `TEST_RUNNER_SBU_PROMPTER_SHOTS`.

## Scarica

- **Mac:** [SbuPrompter-1.1.0.dmg](https://github.com/sbudotdev/apps/releases/download/prompter-1.1.0/SbuPrompter-1.1.0.dmg) (macOS, universale, firmato Developer ID e notarizzato). Apri il dmg e trascina Sbu Prompter in Applicazioni. Note e versioni precedenti: [release prompter-1.1.0](https://github.com/sbudotdev/apps/releases/tag/prompter-1.1.0).
- **iPhone (telecomando):** per ora su TestFlight; su App Store dopo la review.

## Dove sta cosa

- `SbuPrompter/Core`: logica pura senza AppKit (normalizzazione del testo, allineatore voce-copione, cue, scorrimento, conto alla rovescia, comandi e stato). Il target iOS `SbuPrompterRemote` la compilerà come sorgente condiviso.
- `Prompter`: il pannello (notch, pillola, finestra mobile) e il controller che applica i comandi.
- `Speech`: microfono scelto nelle impostazioni (`Microphones`, per UID Core Audio; riparte se colleghi o scolleghi un microfono) e `SFSpeechRecognizer` solo sul dispositivo. Dopo 5 s di silenzio il prompter dice quale ingresso sta ascoltando.
- `Shortcuts`: scorciatoie globali con `RegisterEventHotKey` (niente permesso Accessibilità).
- `Library`: copioni in SwiftData con ricerca; importazione (file picker o trascinamento) di `.txt`, `.md`, `.rtf`, `.rtfd`, `.docx`, `.doc`, `.odt`, `.html`, `.pdf`; esportazione in `.txt`; pulsanti Sezione e Interruzione nell'editor.
- `Welcome`: la finestra del primo avvio (riaperta da «Come si usa…» nel menu).
- `Remote`: il lato Mac del telecomando. `RemoteGate` decide chi può comandare (codice di 4 cifre nel menu, poi un token; pausa che raddoppia dopo 5 codici sbagliati), `RemoteServer` fa Multipeer e manda lo stato.
- `Core/RemoteMessage` e `Core/RemoteCodec`: il protocollo, con la versione in ogni messaggio. Un peer con un'altra versione viene rifiutato.
- `../SbuPrompterRemote`: l'app iPhone. `RemoteModel` (stato e abbinamento, testato), `MacLink` (Multipeer), le schermate.

## Argomenti di avvio per il QA (solo build Debug)

| Argomento | Cosa fa |
|---|---|
| `-SbuPrompterSimulateNotch 32` | impagina il pannello come su un notch da 32 pt, sui Mac senza notch |
| `-SbuPrompterForcePill YES` | mostra la pillola anche su un Mac con il notch |
| `-SbuPrompterAllowCapture YES` | rende il prompter visibile agli screenshot (per le immagini dello Store) |
| `-SbuPrompterSnapshots YES` | salva prompter, libreria e impostazioni in PNG nella cartella temporanea dell'app ed esce |
| `-SbuPrompterPeerName "MacBook Pro"` | annuncia il Mac all'iPhone con questo nome invece di quello vero (per gli screenshot dello Store) |
| `-SbuPrompterInMemory YES` | libreria in memoria: parte vuota, con il copione di benvenuto nella lingua dell'avvio, e non tocca i copioni salvati |
| `kill -USR1 <pid>` | salva il prompter dal vivo (`live-N.png`) e scrive lo stato su stderr, con il codice del telecomando e l'iPhone collegato |

Le impostazioni si possono forzare all'avvio con le loro chiavi, per esempio `-layout floating`, `-countdown 0`, `-mode voice`, `-isMirrored YES`.

## Distribuzione

- **Fuori dallo Store:** `./make-dmg.sh 1.1.0` crea `build/dist/SbuPrompter-1.1.0.dmg`, universale, firmato Developer ID; app e dmg sono notarizzati e graffati. Il `.dmg` va nella release GitHub `prompter-<versione>`.
- **App Store e TestFlight:** `fastlane upload` (oppure `platform:osx` / `platform:ios`) carica le build Mac e iPhone sulla versione 1.0; `fastlane metadata` carica i testi. Servono `SBU_TEAM_ID` e la chiave API di App Store Connect (`ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH`).
