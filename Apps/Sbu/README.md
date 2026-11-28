# Sbu

Un'app sola con gli strumenti sbu.dev, ognuno come una pagina del Quaderno. Spike (SBU-464, ADR-0027): oggi tiene Livella, Luna e Abbonamenti, cioè Sbu Level, Sbu Moon e Sbu Subscriptions, con il loro codice.

```sh
python3 merge_strings.py   # dopo ogni modifica alle stringhe della shell o delle tre app
xcodegen generate
xcodebuild test -project Sbu.xcodeproj -scheme Sbu -destination 'platform=iOS Simulator,name=iPhone 17'
```

## Cosa fa

- **Quaderno**: la pagina iniziale. Quanti strumenti tieni (la Cifra) e una riga per ognuno.
- **Strumenti**: aggiungi, togli e riordina. La scelta resta dopo il riavvio.
- **Uno strumento** si apre a tutto schermo, come nella sua app, sotto la striscia «Quaderno» che torna indietro. Anche da un link: `sbu://level`, `sbu://moon`, `sbu://subscriptions`.
- **Impostazioni** condivise, quelle standard di `SbuAppShell`.

Gli intent di Abbonamenti (Siri, Comandi, Spotlight) funzionano anche in Sbu: le loro dipendenze le registra `SbuApp.init`, e una strada lasciata da un intent apre lo strumento Abbonamenti.

Nessun permesso all'avvio: la fotocamera la chiede il Mirino di Livella, le notifiche un avviso di Luna o un promemoria di Abbonamenti, la posizione «Mostra sorgere e tramonto» di Luna.

## Dove sta cosa

- `Sbu/Notebook`: `Tool` (il catalogo) e `Notebook` (gli strumenti scelti, salvati nei default sotto `notebook.tools`). Logica con test in `SbuTests`.
- `Sbu/Views`: `RootView` (shell), `HomeView` (Quaderno), `ToolRow`, `ToolsSheet` (modifica), `ToolPage` (strumento a tutto schermo).
- `Modules/<Strumento>`: la vista pubblica che mostra il `RootView` dell'app. I target `LevelTool`, `MoonTool` e `SubscriptionsTool` sono librerie statiche costruite da questi file e dalla cartella sorgente dell'app (`../SbuLevel/SbuLevel` e così via), senza copiarla.
- `Strings/Shell.xcstrings`: le stringhe della shell. `Sbu/Localizable.xcstrings` è **generato** da `merge_strings.py` (shell più i cataloghi delle tre app): non modificarlo a mano. La build fallisce se non è aggiornato.
- `SbuUITests/ShellFlowTests`: apre ognuno dei tre strumenti dal Quaderno con l'audit di accessibilità, aggiunge uno strumento a un Quaderno vuoto, e `testScreenshots` salva gli screenshot nel risultato dei test (una volta in chiaro, una in scuro con `xcrun simctl ui <device> appearance dark`).

Come si aggiunge uno strumento: ADR-0027.

## Limiti dello spike

- Abbonamenti salva solo su questo iPhone: niente iCloud, niente liste condivise, niente App Group.
- Niente widget e niente icona definitiva (dopo SBU-455).
- Non è su App Store Connect: TestFlight è il ticket successivo.
