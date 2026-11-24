# Sbu Bar — design della 1.0

Approvato da Matteo il 24/11/2026. Comportamento di ogni funzione: `research/apps/bartender.md` (spec da fonti pubbliche, clean room). Distribuzione e vincoli: ADR-0025.

## Cosa è

Un'app Mac gratuita, solo nella barra dei menu, che nasconde, mostra e riordina le icone della barra dei menu, con profili e trigger. Rifà Bartender (20 $ una tantum, Pro 15 $ l'anno). Nella 1.0: il nucleo, i profili e i trigger, i gruppi. Fuori: i widget (meteo, calendario, musica, appunti, batteria delle cuffie) e Top Shelf, che sono un'altra app.

## Progetto

- `Apps/SbuBar`, XcodeGen come Sbu Keys: `platform: macOS`, macOS 15, SbuKit, Swift 6 con `MainActor` di default, strict concurrency completa, `LSUIElement`.
- Bundle id `dev.sbu.bar`, nome «Sbu Bar», accento `accent-bar` da aggiungere a `Design/tokens.json`.
- Fuori dalla sandbox, hardened runtime, Developer ID, `make-dmg.sh` come Sbu Keys (ADR-0025).
- Stringhe IT ed EN in `Localizable.xcstrings`, seconda persona singolare.

## Moduli

Una cartella per modulo, un tipo per file. Le parti di sistema (Accessibilità, cattura delle immagini, eventi, preferenze globali, osservatori) stanno dietro protocolli, con versioni finte nei test.

| Modulo | Fa | Dipende da |
|---|---|---|
| `Items` | legge le icone della barra, una identità stabile per icona (bundle id dell'app più nome o indice dell'elemento), le segue quando compaiono, spariscono o un'app si riavvia | protocollo `MenuBarReading` |
| `Sections` | modello puro: Mostrate, Nascoste, Sempre nascoste, gruppi, ordine salvato; confronto tra ordine reale e salvato, con la lista di spostamenti necessari | niente |
| `Arranger` | applica gli spostamenti alla barra reale senza muovere il puntatore, con un tempo limite; riferisce successo, parziale o fallito | `Sections`, protocollo `MenuBarMoving` |
| `Reveal` | mostra le Nascoste con clic sull'icona di Sbu Bar, passaggio del mouse, scorrimento o scorciatoia; le rinasconde dopo un tempo o al clic altrove; mostra un'icona nascosta quando cambia aspetto | `Items`, `Arranger` |
| `Strip` | la barra separata sotto la barra dei menu: immagini delle icone nascoste, clic inoltrato all'icona vera | `Items`, protocollo `ItemImaging` |
| `Search` | campo di ricerca da tastiera tra tutte le icone, apre quella scelta | `Items` |
| `Appearance` | colore, bordi, angoli, ombra della barra dei menu; spaziatura con avviso e ripristino | protocollo `GlobalDefaults` |
| `Profiles` | profilo = disposizione completa (sezioni, ordine, gruppi, aspetto); applicare un profilo | `Sections`, `Appearance` |
| `Triggers` | valutazione pura delle condizioni (batteria, Wi-Fi, posizione con raggio scelta su una mappa MapKit come in Sbu Find, ora e data, app, microfono, VPN, Time Machine, icona, script) e azioni (applica profilo, mostra icona finché vera); osservatori sottili per ogni segnale | `Profiles`, protocolli per ogni segnale |
| `Displays` | notch e più schermi: indicatore per le icone sotto il notch, stessa disposizione su ogni schermo | `Items` |
| `Store` | un file JSON versionato in Application Support, con copia di riserva; esporta e importa | niente |
| `Settings` | la finestra Impostazioni SwiftUI con i componenti SbuKit | tutti |
| `Welcome` | primo avvio e permessi | `Settings` |

## Flussi

1. **Primo avvio**: pannello alla `SbuEmpty`, una frase e un pulsante per Accessibilità e per Registrazione schermo. Con i permessi, tutte le icone vanno in Mostrate: niente sparisce senza una scelta.
2. **Disporre**: Impostazioni › Icone, tre liste e i gruppi, trascinamento tra liste. Al salvataggio `Arranger` fa combaciare la barra. Cifra della schermata: le icone nascoste (`SbuFigure`); punto fermo `.set` quando la barra combacia col modello.
3. **Mostrare**: vedi `Reveal`; con la barra separata accesa le Nascoste compaiono lì.
4. **Trigger**: condizione vera, si applica il profilo o si mostra l'icona; condizione falsa, si torna allo stato di prima.
5. **Ricerca**: scorciatoia, scrivi, frecce, Invio apre l'icona.

## Errori

- Permesso revocato: Sbu Bar smette di nascondere, rimette tutto in vista, avviso con «Apri Impostazioni di Sistema».
- App chiusa o riavviata: l'icona mantiene il posto grazie all'identità stabile.
- Riordino oltre il tempo limite: si ferma, lascia la barra com'è, lo dice in una riga, nessun ritentativo infinito.
- Uscita o crash: all'uscita tutte le icone tornano visibili.
- File delle impostazioni rovinato: si riparte dalla copia di riserva.

## Test

- Swift Testing per `Sections`, `Triggers` (orologio, batteria e rete finti), `Profiles`, `Store` (versioni del JSON), il confronto tra ordine reale e salvato.
- XCUITest per i flussi delle Impostazioni con `performAccessibilityAudit`; `#Preview` chiaro e scuro per ogni vista.
- Prova a mano sul Mac di Matteo per `Arranger`, `Strip` e i trigger di sistema.

## Ordine di lavoro

1. Spike di `Arranger`: riordinare un'icona di un'altra app senza muovere il puntatore. Se non riesce, ci si ferma e si decide con Matteo.
2. `Items` e `Sections`.
3. `Reveal`.
4. `Settings` e `Welcome`.
5. `Strip`.
6. `Search`.
7. `Appearance` e spaziatura.
8. `Profiles` e `Triggers`.
9. Gruppi.
10. `Displays`.
11. Icona, README con l'elenco delle API non documentate, .dmg.

Il codice resta sul branch locale `app/bar`: niente push né merge prima della review di Matteo.
