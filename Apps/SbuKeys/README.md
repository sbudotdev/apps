# Sbu Keys (Mac)

Un suono da tastiera meccanica a ogni tasto, in ogni app, dalla barra dei menu. Rifà Klack (4,99 $, Mac App Store) gratis. Ricerca: `research/apps/klack.md`. ADR-0024 per SbuKit sul Mac.

```sh
xcodegen generate
xcodebuild test -project SbuKeys.xcodeproj -scheme SbuKeys -destination platform=macOS
```

## Permesso

Serve **Monitoraggio input** (Impostazioni di Sistema → Privacy e sicurezza). L'app ascolta i tasti con un event tap in sola lettura: riceve solo il codice del tasto e se è premuto o rilasciato, mai i caratteri. Conta i tasti di oggi e non salva altro. Con Secure Input attivo (campi password) macOS non manda gli eventi, quindi lì non suona. Senza il permesso il pannello mostra «Consenti»; l'app controlla ogni secondo e parte appena il permesso arriva.

Il permesso si dà al singolo binario: la build Debug e quella Release sono due voci diverse nella lista.

## Dove sta cosa

- `Core`: logica pura con test. `KeyKind` (tasto normale, spazio, tasti larghi), `KeySwitch` (lineare, tattile, clic) e il nome dei campioni, `KeyPan` (posizione stereo del tasto su una tastiera ANSI), `KeystrokeTally` (tasti di oggi, riparte a mezzanotte).
- `Input/KeyTap`: l'event tap di Core Graphics, sul run loop principale. Ignora la ripetizione dei tasti tenuti premuti.
- `Audio/KeySoundPlayer`: `AVAudioEngine` con 8 voci a turno (player, varispeed per l'altezza casuale, mixer per il pan), campioni già in memoria. Si riavvia quando cambia l'uscita audio.
- `Panel`: il pannello della barra dei menu: la cifra (tasti oggi), suono sì/no, switch, volume, posizione.
- `Welcome`: la finestra del primo avvio, che chiede il permesso.

## Suoni

`Sounds/<switch>-<tasto>-<down|up>.caf`: 3 switch × 3 tasti × pressione e rilascio = 18 file, mono 44,1 kHz. **Oggi sono segnaposto sintetici** (`python3 Tools/make_key_sounds.py`). Vanno sostituiti con registrazioni di una tastiera meccanica vera, con gli stessi nomi; il test `everySampleIsInTheBundle` controlla che ci siano tutti.

## Distribuzione

Sta nella sandbox, quindi va sia sul Mac App Store sia in `.dmg` (ADR-0024). `./make-dmg.sh 1.0` crea `build/dist/SbuKeys-1.0.dmg` firmato Developer ID e notarizzato. Il record su App Store Connect, fastlane e la pagina sul sito non ci sono ancora.
