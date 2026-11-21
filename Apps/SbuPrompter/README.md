# Sbu Prompter (Mac)

Teleprompter gratuito per Mac: il copione scorre nel notch, sotto la fotocamera, e non compare quando condividi lo schermo, nelle registrazioni o negli screenshot. Spec: SBU-166, ADR-0024 per SbuKit sul Mac.

```sh
xcodegen generate
xcodebuild test -project SbuPrompter.xcodeproj -scheme SbuPrompter -destination platform=macOS
```

## Dove sta cosa

- `SbuPrompter/Core`: logica pura senza AppKit (normalizzazione del testo, allineatore voce-copione, cue, scorrimento, conto alla rovescia, comandi e stato). Il target iOS `SbuPrompterRemote` la compilerà come sorgente condiviso.
- `Prompter`: il pannello (notch, pillola, finestra mobile) e il controller che applica i comandi.
- `Speech`: microfono e `SFSpeechRecognizer` solo sul dispositivo.
- `Shortcuts`: scorciatoie globali con `RegisterEventHotKey` (niente permesso Accessibilità).
- `Library`: copioni in SwiftData, importazione `.txt`, `.md`, `.rtf`.

## Argomenti di avvio per il QA (solo build Debug)

| Argomento | Cosa fa |
|---|---|
| `-SbuPrompterSimulateNotch 32` | impagina il pannello come su un notch da 32 pt, sui Mac senza notch |
| `-SbuPrompterForcePill YES` | mostra la pillola anche su un Mac con il notch |
| `-SbuPrompterAllowCapture YES` | rende il prompter visibile agli screenshot (per le immagini dello Store) |
| `-SbuPrompterSnapshots YES` | salva prompter, libreria e impostazioni in PNG nella cartella temporanea dell'app ed esce |
| `kill -USR1 <pid>` | salva il prompter dal vivo (`live-N.png`) e scrive lo stato su stderr |

Le impostazioni si possono forzare all'avvio con le loro chiavi, per esempio `-layout floating`, `-countdown 0`, `-mode voice`, `-isMirrored YES`.
