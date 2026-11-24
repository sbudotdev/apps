# Sbu Bar (nome provvisorio): spec di comportamento su Bartender

Bartender di Surtees Studios (macbartender.com; dal 2024 di proprietà di Applause): gestisce le icone della barra dei menu di macOS. Nasconde quelle che non servono, le mostra quando servono, le riordina, cambia l'aspetto della barra. Esiste dal 2013 circa; oggi convivono tre versioni, una per sistema.

Spec in clean room: descrive solo cosa vede e fa l'utente, ricavato da pagine pubbliche (sito, note di rilascio, recensioni, documentazione Apple). Nessun binario di Bartender aperto o analizzato. La colonna "Framework" indica l'API Apple pubblica che pensiamo di usare noi, non come lo fa Bartender.

## 1. L'originale in sintesi

| | |
|---|---|
| Produttore | Surtees Studios (Ben Surtees). Venduta ad Applause all'inizio del 2024, resa nota solo a giugno 2024 da MacRumors e TidBITS, con polemica sui permessi di Accessibilità e Registrazione schermo [9][10] |
| Versioni | **Bartender 5** per Sonoma e Sequoia (uscita a settembre/ottobre 2023 con Sonoma [5]); **Bartender 6** per Sequoia e Tahoe (uscita il 15/09/2025 con macOS 26 [8]; ultima nota letta 6.6.2 [3]); **Bartender 7** per macOS 27 "Golden Gate" (beta pubbliche, Setapp elenca 7.2.1; la data di uscita esatta non l'ho trovata [1][4][6]) |
| Requisiti | Bartender 6: macOS 15 o 26. Bartender 7: macOS 27, supporto a Tahoe promesso dopo il lancio [1][6] |
| Prezzo | Licenza una tantum: Bartender 6 a 20 $ (20 € in Europa, upgrade 12 €) [8][11][12]. **Bartender Pro** in abbonamento: 15 $ l'anno, aggiunge Top Shelf e gli upgrade maggiori [11][12]. **Mega Supporter**: a vita, prezzo non pubblicato in chiaro. Prova gratuita di 4 settimane; Pro con 14 giorni. Una licenza vale per tutti i Mac del titolare. Anche su Setapp [1][7] |
| Cosa è a pagamento | Tutta l'app dopo la prova. Pro aggiunge Top Shelf (widget nel notch, file, appunti) |
| Alternative gratis | **Ice** (jordanbaird, GPL-3.0; sviluppo fermo, problemi su Tahoe) e i suoi fork **Thaw** (GPL-3.0, 2.0 nel 2026) e IceMelt [13]; **Hidden Bar** (Dwarves Foundation, MIT, gratis sul Mac App Store; solo nascondi/mostra e scorciatoia) [14]. macOS 26 ha l'elenco "Consenti nella barra dei menu" in Impostazioni, che spegne un'icona ma non nasconde, non riordina e non mostra a richiesta [15] |

> **Filtro di nicchia (`docs/factory.md`).** Il prezzo è basso ma Bartender ora spinge un abbonamento (Pro) e la vendita silenziosa del 2024 ha rotto la fiducia: proprio il pubblico che cerca un'app con i permessi di Accessibilità e Registrazione schermo da qualcuno di cui fidarsi. Le alternative gratis sono GPL (Ice, Thaw: non riusabili) o minime (Hidden Bar). Sbu Bar ha spazio: nativa, open source, nessuna rete, stessa funzione di Bartender 6/7 senza Top Shelf.

Distribuzione: **Developer ID + notarizzazione, `.dmg` da sbu.dev, fuori dalla sandbox** (ADR-0022, come Sbu Seasons). Accessibilità verso altre app ed eventi sintetici non sono ammessi nella sandbox. Target **macOS 15** (ADR-0024, usa SbuKit).

## 2. Matrice delle feature

Legenda Sbu: **core** = nella 1.0, stessa funzione dell'originale; **nice** = dopo la 1.0 o se costa poco; **skip** = non si fa; **altra app** = fuori da Sbu Bar, eventualmente un'app Sbu separata.

| # | Feature | A pagamento? | Sbu | Framework Apple pubblico | Conflitto con CLAUDE.md? |
|---|---|---|---|---|---|
| 1 | Tre sezioni: Mostrate, Nascoste, Sempre nascoste | sì (tutta l'app) | core | `NSStatusItem` propri come separatori; elenco delle icone altrui con `CGWindowListCopyWindowInfo` | no |
| 2 | Riordino delle icone (trascina nell'editor, l'app ripete l'ordine) | sì | core | eventi ⌘-trascina sintetici con `CGEvent` (Accessibilità); `AXUIElement` per leggere posizioni | no |
| 3 | Posizione delle icone nuove (mostrate o nascoste, a scelta) | sì | core | come 1 | no |
| 4 | Barra separata (Bartender Bar) sotto la barra dei menu, con le icone nascoste | sì | core | `NSPanel` non attivante; immagini con ScreenCaptureKit (`SCScreenshotManager`) o icona dell'app senza permesso | no |
| 5 | Mostra le nascoste al passaggio del mouse, con ritardo regolabile | sì | core | `NSEvent.addGlobalMonitorForEvents` (mouse) | no |
| 6 | Mostra al clic su uno spazio vuoto della barra | sì | core | come 5 | no |
| 7 | Mostra con scorrimento o swipe sulla barra | sì | core | come 5 (`.scrollWheel`) | no |
| 8 | Nascondi di nuovo dopo un tempo, o quando il mouse esce | sì | core | `Task.sleep` / timer | no |
| 9 | Mostra temporaneamente le icone già visibili al posto delle nascoste quando manca spazio (scambio) | sì | core | come 1 | no |
| 10 | Mostra un'icona quando si aggiorna ("Show for updates": qualunque cambiamento, o immagine che corrisponde) | sì | core | ScreenCaptureKit per confrontare l'immagine; senza permesso solo cambi di larghezza/titolo via `AXUIElement` | no; immagini tenute solo in memoria |
| 11 | Ricerca rapida tra le icone da tastiera e attivazione (Quick Search / Command Bar) | sì | core | `NSPanel` con campo di testo; `AXUIElementPerformAction(kAXPressAction)` sull'icona | no |
| 12 | Scorciatoie globali: mostra nascoste, mostra sempre nascoste, ricerca, una per icona, una per profilo, nascondi tutta la barra (modalità concentrazione) | sì | core | `RegisterEventHotKey` (Carbon, pubblico) o `NSEvent` globale | no |
| 13 | ⌥-clic sull'icona dell'app per mostrare anche le Sempre nascoste | sì | core | `NSStatusItem` | no |
| 14 | Aspetto della barra: colore pieno, sfumatura, vetro/materiale (spessore, chiaro/scuro/sistema), bordo (colore, spessore), ombra, angoli arrotondati, forma a pillola o due pillole, angoli dello schermo arrotondati | sì | core | finestra `NSWindow` senza bordi sotto la barra, a livello appena sotto `.statusBar`; `NSVisualEffectView`/`glassEffect` | stili ammessi: sono personalizzazione dell'utente, non dell'interfaccia Sbu |
| 15 | Stile diverso per ogni schermo; stile predefinito per gli schermi nuovi | sì | core | `NSScreen.screens`, `didChangeScreenParametersNotification` | no |
| 16 | Spazio tra le icone: Predefinito, Piccolo, Minimo, Nessuno | sì | core | preferenze globali di sistema `NSStatusItemSpacing` / `NSStatusItemSelectionPadding` (note pubblicamente, non documentate da Apple); servono logout e login | tenuta con avviso (deciso da Matteo il 24/11): l'avviso spiega il logout, «Predefinita» ripristina il valore di sistema |
| 17 | Notch: le icone coperte dal notch finiscono nelle nascoste, raggiungibili con clic o scorciatoia; scambio con le mostrate | sì | core | `NSScreen.safeAreaInsets`, `auxiliaryTopLeftArea`/`auxiliaryTopRightArea` | no |
| 18 | Più schermi: la barra di ogni schermo, Bartender Bar sullo schermo del puntatore | sì | core | `NSScreen` | no |
| 19 | Profili (preset): layout completi salvati, quanti se ne vuole, cambio istantaneo | sì | core | `UserDefaults`/file JSON locale | no |
| 20 | Profilo legato a una configurazione di schermi | sì | core | `NSScreen` + `CGDisplayCreateUUIDFromDisplayID` | no |
| 21 | Profilo applicato all'avvio; ripristino della barra all'uscita | sì | core | — | no |
| 22 | Profilo legato a una modalità Full immersione (Focus) | sì | core | App Intents `SetFocusFilterIntent` (filtro di Full immersione) | no |
| 23 | Trigger Batteria: a batteria, in carica, sotto/sopra un livello | sì | core | IOKit `IOPSCopyPowerSourcesInfo`, `IOPSNotificationCreateRunLoopSource` | no |
| 24 | Trigger Wi-Fi: connesso, non connesso, rete specifica | sì | core | CoreWLAN `CWWiFiClient`; il nome della rete richiede il permesso Posizione | no; il nome rete resta sul Mac |
| 25 | Trigger Posizione: in un luogo | sì | core | Core Location (`CLMonitor`/regioni) | no; mappa MapKit di sistema con puntina, raggio e ricerca dell'indirizzo, come Sbu Find (deciso da Matteo il 24/11) |
| 26 | Trigger Ora e data: fasce orarie, giorni della settimana | sì | core | `Calendar`, timer | no |
| 27 | Trigger App: app attiva o in esecuzione | sì | core | `NSWorkspace` (`frontmostApplication`, `runningApplications`, notifiche) | no |
| 28 | Trigger Time Machine: backup in corso | sì | core | stato di `tmutil status` letto in locale, o icona di Time Machine che cambia (trigger 10) | da verificare: nessuna API pubblica diretta |
| 29 | Trigger Microfono in uso (es. in riunione) | sì | core | Core Audio `kAudioDevicePropertyDeviceIsRunningSomewhere` | no |
| 30 | Trigger VPN attiva / rete Wi-Fi non protetta (esempio di Bartender 7) | sì | core | `NEVPNManager` solo per le VPN proprie: per le altre, interfacce `utun` via `getifaddrs`; sicurezza della rete da CoreWLAN | no |
| 31 | Trigger Script: AppleScript o shell dell'utente, eseguito ogni N secondi, vero/falso | sì | core | `NSAppleScript`, `Process` | no: lo script è dell'utente; Sbu non ne fornisce di remoti |
| 32 | Più condizioni combinate in un trigger (tutte / almeno una) | sì | core | logica pura, testata | no |
| 33 | Cosa fa un trigger: mostra icone scelte, oppure applica un profilo; torna indietro quando la condizione cade | sì | core | — | no |
| 34 | Gruppi: più icone in una sola, con simbolo o emoji; barre secondarie | sì | core (deciso da Matteo il 24/11) | `NSStatusItem` con menu o pannello | no |
| 35 | Separatori con testo, emoji o SF Symbol, larghezza regolabile, per profilo | sì | nice | `NSStatusItem` | no |
| 36 | AppleScript: elenca icone, le mostra, le clicca (sinistro, destro, ⌥) | sì | nice | dizionario `.sdef` | no |
| 37 | Comandi Rapidi / App Intents (le stesse azioni di AppleScript) | sì | nice | App Intents | no |
| 38 | Ricerca da Spotlight ("Bartender" + nome icona) | sì | nice | App Intents con `AppShortcutsProvider` / Core Spotlight | no |
| 39 | Nascondere anche Orologio e Centro di Controllo | sì | core | come 1 (dove macOS lo consente) | no |
| 40 | Elenco delle icone disattivate in Centro di Controllo (macOS 27, sperimentale in Bartender 7) | sì | nice | — | da verificare su macOS 27 |
| 41 | Risparmio energetico: meno aggiornamenti dal vivo a batteria | sì | core (come comportamento, non come opzione) | `ProcessInfo.isLowPowerModeEnabled`, IOKit | no |
| 42 | Ricattura delle immagini e "Riavvia barra dei menu" se qualcosa si blocca | sì | core | ScreenCaptureKit | no |
| 43 | Widget propri nella barra (meteo, calendario, musica, CPU, script personalizzati) | sì | **altra app** | — | meteo = rete |
| 44 | Cronologia appunti (nella Command Bar, Pro) | sì (Pro) | **altra app** | — | no, ma non è la cosa sola di Sbu Bar |
| 45 | Top Shelf (Pro): widget, file, appunti, banner, stato degli agenti nel notch | sì (abbonamento) | **altra app** | — | no |
| 46 | Batteria delle cuffie Bluetooth, avvisi AirPods (Top Shelf) | sì (Pro) | **altra app** | — | no |
| 47 | Aggiornamenti automatici dall'app | — | skip | — | sì: rete |
| 48 | Licenza, prova di 4 settimane, attivazione da link | — | skip | — | sì: rete e acquisto |
| 49 | Invio di feedback e log al supporto dall'app | — | skip | — | sì: rete |
| 50 | Azioni via URL nelle automazioni (Bartender 7) | sì | dubbio: core se è solo uno schema `sbubar://` locale; skip se chiama URL web | `onOpenURL` | sì se tocca la rete |

**Feature core: 36** (righe 1-33, 39, 41, 42). La 28 (Time Machine) è core ma senza un'API pubblica diretta: da verificare.

## 3. Comportamento visto dall'utente (feature core)

L'app vive nella barra dei menu (`LSUIElement`), senza Dock. La sua icona è il punto fermo `mark` in `ink`: è anche il separatore tra Mostrate e Nascoste. Le impostazioni sono la finestra `Settings` di SwiftUI (ADR-0024), con pagine: **Disposizione**, **Mostra**, **Barra**, **Aspetto**, **Profili**, **Trigger**, **Scorciatoie**, **Permessi**, **Licenze**.

### 3.1 Sezioni e disposizione (1, 2, 3, 9, 39)

- **Cosa fa.** Ogni icona della barra sta in una di tre sezioni. *Mostrate*: sempre visibili. *Nascoste*: compaiono solo quando chiedi di vederle. *Sempre nascoste*: compaiono solo con un gesto in più (⌥-clic sull'icona di Sbu Bar o la loro scorciatoia), mai al passaggio del mouse.
- **Dove.** Impostazioni › Disposizione: tre liste con l'immagine vera di ogni icona (o l'icona dell'app senza Registrazione schermo), da trascinare tra sezioni e dentro una sezione. Un chip "Le nuove icone vanno qui" si trascina nella sezione che vuoi (predefinito: Nascoste). Pulsante "Ricattura" per aggiornare le immagini.
- **Ordine mantenuto.** Sbu Bar ricorda l'ordine e lo ripristina dopo riavvii del Mac, riavvii delle app e cambi di schermo. Un'app che si riavvia rimette l'icona dove macOS decide; Sbu Bar la riporta al suo posto. Due copie della stessa app (o due icone della stessa app) tengono ciascuna il proprio posto.
- **Puntatore.** Riordinare non deve mai spostare il tuo puntatore in modo visibile (Bartender 6 su Tahoe lo faceva, Bartender 7 no [6]). Se il sistema lo richiede, il riordino si fa solo quando premi "Riordina ora", mai di sorpresa, e si interrompe se blocchi lo schermo, cambi Spazio o vai a tutto schermo.
- **Scambio quando manca spazio.** Quando mostri le Nascoste e non c'è posto, Sbu Bar nasconde per un momento le Mostrate per far spazio, poi le rimette (opzione in Mostra, attiva di default sui Mac con notch).
- **Casi limite.** Icona di un'app chiusa: sparisce dalla lista attiva ma resta ricordata, grigia, con la sezione scelta; riappare lì quando l'app riparte. Icona che macOS non sa identificare: resta in una sezione "Da riconoscere" e non viene mossa finché non ha un nome. Icone di sistema non spostabili (es. Orologio su alcune versioni): si possono nascondere ma non riordinare dentro le Mostrate, e l'editor lo dice. Icona tolta dall'utente in Impostazioni di Sistema › Barra dei menu (macOS 26+): non è nella barra, quindi Sbu Bar non la vede e lo spiega in una riga.

### 3.2 Mostrare le nascoste (5, 6, 7, 8, 13)

- **Gesti**, ciascuno attivabile in Impostazioni › Mostra: passaggio del mouse sulla barra (con ritardo regolabile, es. 0-1 s), clic su uno spazio vuoto della barra, scorrimento o swipe sulla barra, clic sull'icona di Sbu Bar, scorciatoia. ⌥-clic sull'icona di Sbu Bar mostra anche le Sempre nascoste.
- **Dove compaiono**: nella barra stessa (le nascoste si aprono accanto al separatore) oppure nella **Barra Sbu** (3.3), a scelta.
- **Si richiudono** quando il mouse lascia la barra o dopo un tempo scelto (es. 5, 10, 30 s), e sempre dopo che hai usato un'icona e il suo menu si è chiuso.
- **Casi limite.** Durante il trascinamento di una finestra o a tutto schermo il passaggio del mouse non apre nulla. Su più schermi si apre la barra dello schermo sotto il puntatore.

### 3.3 Barra Sbu (la "Bartender Bar") (4, 18)

- **Cosa fa.** Un pannello sottile appena sotto la barra dei menu con le icone Nascoste (e, a richiesta, le Sempre nascoste). Clic su un'icona: si comporta come il clic sull'icona vera (si apre il suo menu). Clic destro e ⌥-clic passano all'icona vera.
- **Si apre** con passaggio del mouse, clic o scorciatoia; con la scorciatoia appare dove sta il puntatore.
- **Aspetto proprio**, separato da quello della barra dei menu (vetro chiaro/scuro/sistema, spaziatura).
- **Casi limite.** Un'icona larga (testo, contatori) si mostra alla sua larghezza naturale. Se un'icona appena cliccata non ha spazio nel lato giusto, va sul lato opposto. Clic su un'icona già presente nella Barra Sbu non la duplica. Senza Registrazione schermo mostra l'icona dell'app con il nome sotto; con più icone della stessa app le distingue con il nome dell'icona se macOS lo fornisce, altrimenti con un numero.

### 3.4 Icone che compaiono quando cambiano (10)

- **Cosa fa.** Un'icona nascosta può comparire da sola per un tempo (es. 5 s, o finché la condizione dura) quando: cambia in qualunque modo; oppure la sua immagine corrisponde a uno stato scelto (es. Dropbox che sincronizza, la VPN accesa). L'immagine di riferimento la scegli catturandola nell'editor.
- **Dove.** Impostazioni › Trigger, tipo "Icona": scegli l'icona, "Qualsiasi cambiamento" o "Corrisponde a questa immagine".
- **Casi limite.** Le icone che cambiano sempre (orologi, CPU) si possono escludere; Sbu Bar avvisa se un'icona cambia più di N volte al minuto. Senza Registrazione schermo vale solo "Qualsiasi cambiamento" basato su larghezza e titolo, e la pagina lo dice. Il confronto delle immagini si ferma a schermo bloccato e si dirada a batteria (41). Il punto viola di macOS per la cattura dello schermo può comparire: la pagina Permessi lo spiega.

### 3.5 Ricerca rapida (11)

- **Cosa fa.** Una scorciatoia apre un campo di ricerca al centro dello schermo: scrivi parte del nome dell'app o dell'icona, frecce per scegliere, Invio per aprire il menu dell'icona (anche se è nascosta o dietro il notch), ⌘Invio per il clic destro. Nello stesso campo: i profili ("Applica Lavoro") e i trigger ("Esegui").
- **Casi limite.** Icona di un'app chiusa: compare in fondo, grigia, con "Non in esecuzione". Esc chiude senza fare nulla. VoiceOver legge ogni risultato con nome e sezione.

### 3.6 Scorciatoie (12)

Impostazioni › Scorciatoie, tutte vuote di default tranne nessuna (per non rubare combinazioni): mostra Nascoste, mostra Sempre nascoste, apri Barra Sbu, ricerca rapida, nascondi tutta la barra (concentrazione: rimangono solo le icone di sistema essenziali, o nessuna), una per ogni profilo, una per ogni icona (la mostra e ne apre il menu). Conflitto con un'altra scorciatoia di sistema: si avvisa e non si registra.

### 3.7 Aspetto della barra dei menu (14, 15)

- **Cosa fa.** Disegna uno sfondo sotto la barra dei menu: Standard (nessuno), Colore pieno, Sfumatura (due colori, angolo), Vetro o Materiale (spessore; chiaro, scuro, come il sistema o come la barra). Opzioni: bordo (colore, spessore), ombra, angoli arrotondati, forma a pillola intera o a due pillole (sinistra con i menu dell'app, destra con le icone), angoli dello schermo arrotondati o banda nera sotto una barra arrotondata. "Ripristina barra" torna a Standard.
- **Dove.** Impostazioni › Aspetto, anche dal clic destro su uno spazio vuoto della barra. Anteprima dal vivo.
- **Per schermo**: ogni schermo ha il suo stile; uno stile predefinito per gli schermi che colleghi per la prima volta.
- **Casi limite.** Il colore del testo della barra lo sceglie macOS (chiaro/scuro), non Sbu Bar: con uno sfondo che lo rende illeggibile l'anteprima avvisa del contrasto. Barra nascosta in automatico (opzione di macOS) e app a tutto schermo: lo sfondo segue la barra e sparisce con lei. Sfondo scrivania che cambia: nessun effetto sugli stili pieni.
- **Nota design system.** Gli stili li sceglie l'utente per la sua barra; l'interfaccia di Sbu Bar resta Quaderno (carta, inchiostro, un punto fermo).

### 3.8 Spazio tra le icone (16)

Impostazioni › Aspetto › Spaziatura: Predefinita, Piccola (circa 2 icone in più), Minima (circa 4 in più), Nessuna. Dopo il cambio serve uscire e rientrare nell'account (o riavviare le app nella barra): un pulsante "Esci ora" lo fa dopo conferma. "Predefinita" riporta il valore di sistema, anche se disinstalli Sbu Bar (lo si dice nella pagina).

### 3.9 Notch e più schermi (17, 18, 20)

- **Notch.** Sui MacBook con notch le icone che finirebbero dietro il notch (o sotto i menu di un'app con molti menu) passano da sole tra le Nascoste e si raggiungono con clic, scorciatoia, ricerca o Barra Sbu. Opzione "Scambia mostrate e nascoste quando manca spazio" (3.1). Le icone accanto al notch non devono tremolare né spostarsi di continuo.
- **Più schermi.** macOS mostra la stessa barra su ogni schermo; Sbu Bar applica la disposizione su tutti, lo stile per schermo, e apre le nascoste sullo schermo del puntatore. Collegare o staccare un monitor esterno può cambiare lo spazio: Sbu Bar ricalcola. Un profilo può essere legato a una configurazione di schermi ("Scrivania", "In giro") e si applica da solo quando la riconosce.

### 3.10 Profili (19, 20, 21, 22)

- **Cosa sono.** Un profilo è una disposizione completa: sezione di ogni icona, ordine, separatori, gruppi, stile della barra. Quanti ne vuoi (es. Lavoro, Concentrazione, Gioco, In giro, Registrazione schermo con le sole icone di sistema).
- **Come si applicano**: dal menu dell'icona di Sbu Bar, dalla ricerca rapida, con la loro scorciatoia, con un trigger, con una modalità Full immersione (filtro di Full immersione di macOS), con una configurazione di schermi, all'avvio. Opzione "All'uscita ripristina la barra".
- **Dove.** Impostazioni › Profili: lista, duplica, rinomina, elimina (con conferma).
- **Casi limite.** Due profili che si applicano insieme (Full immersione e trigger): vince l'ultimo evento, e il menu mostra quale profilo è attivo. Icona presente nel profilo ma non nella barra: si ignora e si applica quando ricompare. Cambio di profilo mentre un menu è aperto: si aspetta che si chiuda.

### 3.11 Trigger (23-33)

- **Cosa fa un trigger**: quando le condizioni sono vere, *mostra* icone scelte (anche dalle Sempre nascoste) oppure *applica* un profilo; quando tornano false, rimette com'era.
- **Tipi di condizione**: Batteria (a batteria, in carica, sotto o sopra una percentuale); Wi-Fi (connesso, non connesso, una rete, rete non protetta); Posizione (entro un raggio da un luogo scelto sulla mappa, con la ricerca dell'indirizzo o la posizione attuale); Ora e data (fascia oraria, giorni); App (una app attiva in primo piano, o in esecuzione); Microfono in uso; VPN attiva; Time Machine in backup; Icona (3.4); Script (AppleScript o shell tuo, ogni N secondi, vero se restituisce `true`/codice 0).
- **Combinazioni**: più condizioni in un trigger, "tutte" o "almeno una".
- **Dove.** Impostazioni › Trigger: lista con interruttore per ciascuno, editor semplice (Quando… / Allora…). Trigger predefiniti spenti: "Batteria sotto 20%: mostra Batteria", "Wi-Fi assente: mostra Wi-Fi", "Microfono in uso: mostra le icone di videochiamata".
- **Casi limite.** Trigger che si attiva e disattiva di continuo: si stabilizza (un cambio ogni pochi secondi al massimo). Uno script che va in errore o supera 5 s: il trigger risulta falso e la riga mostra "Errore nello script". Posizione o Wi-Fi senza permesso Posizione: il trigger è sospeso e lo dice con una parola e un simbolo. Il Mac che si risveglia: i trigger si rivalutano subito. Un trigger non deve mai interrompere un clic in corso sulla barra.

### 3.12 Affidabilità (41, 42)

A batteria gli aggiornamenti delle immagini si diradano. Se la barra smette di rispondere, "Ricattura" e "Riavvia barra" nel menu dell'app. Sbu Bar si avvia all'accesso (`SMAppService.mainApp`), opzione attiva dopo il primo avvio.

## 4. Permessi di sistema

| Permesso | Perché | Se lo neghi |
|---|---|---|
| **Accessibilità** | Leggere dove stanno le icone delle altre app, aprirle (Barra Sbu, ricerca, scorciatoie), riordinarle | Sbu Bar non può riordinare né aprire icone nascoste: resta solo il separatore che nasconde quello che sta a sinistra. Il primo avvio lo spiega con una frase e un pulsante che apre Impostazioni di Sistema › Privacy e sicurezza › Accessibilità |
| **Registrazione schermo e audio di sistema** (facoltativo) | Fare le immagini delle icone per l'editor, la Barra Sbu e il trigger "corrisponde a questa immagine". Solo la striscia della barra, solo in memoria, mai salvate né inviate | Al posto delle immagini, l'icona dell'app con il nome; trigger Icona solo su "qualsiasi cambiamento". Il punto viola di macOS non compare |
| **Posizione** (facoltativo) | Trigger Posizione; il nome della rete Wi-Fi (macOS lo consegna solo con questo permesso) | Quei trigger restano sospesi; gli altri funzionano |
| **Automazione / Eventi Apple** (solo se usi script che controllano altre app) | Il trigger Script con AppleScript | Lo script fallisce, il trigger è falso con "Errore nello script" |
| **Microfono**: non serve | Il trigger "Microfono in uso" legge solo se un dispositivo è attivo, mai l'audio | — |
| "Accesso alla barra dei menu" di macOS 27 | Bartender 7 chiede un permesso con questo nome su macOS 27 [4] | Da verificare sulla documentazione Apple di macOS 27 prima di scrivere codice |

Nessun permesso si chiede all'avvio senza contesto: il primo avvio mostra `SbuEmpty` ("0" con il punto in attesa, una frase, un pulsante "Consenti l'accesso"), poi apre Impostazioni di Sistema. Se un permesso viene tolto mentre l'app gira, Sbu Bar torna a quella schermata e rimette visibili tutte le icone, così nessuna resta irraggiungibile. Per lo stesso motivo, all'uscita e alla disinstallazione tutte le icone tornano visibili.

## 5. Cosa togliamo e cosa lo sostituisce

| Nell'originale | In Sbu Bar |
|---|---|
| Aggiornamenti automatici dall'app (rete) | Nessun controllo di rete. La versione è scritta in Impostazioni › Info con un link a sbu.dev che apre Safari |
| Licenza, prova di 4 settimane, attivazione, upgrade a pagamento, Pro in abbonamento, Mega Supporter | Tutto gratis, nessuna licenza |
| Feedback e log inviati al supporto | "Esporta log" salva un file locale che l'utente allega dove vuole; link alle issue pubbliche in Safari |
| Widget meteo, calendario, musica, CPU, appunti, batteria cuffie; Top Shelf | Fuori: altra app (eventuale Sbu dedicata). Sbu Bar fa una cosa sola |
| Widget con script personalizzati nella barra | Fuori (altra app); il trigger Script resta perché mostra/nasconde icone esistenti |
| Azioni via URL nelle automazioni | Solo uno schema locale `sbubar://` (applica profilo, mostra nascoste); niente URL web |
| Stato degli agenti AI nel notch (Top Shelf) | Fuori |
| Setapp | No |

Unica rete ammessa: la mappa MapKit del trigger Posizione (tessere e ricerca dell'indirizzo dai servizi di Apple), come in Sbu Find (deciso da Matteo il 24/11). Niente passa da sbu.dev o da terzi.

## 6. Fonti

Consultate il 24/11/2026.

1. macbartender.com, pagina prodotto Bartender 7 e FAQ: https://www.macbartender.com/
2. Bartender 5, pagina prodotto: https://www.macbartender.com/Bartender5/
3. Bartender 6, note di rilascio: https://macbartender.com/Bartender6/release_notes/
4. Bartender 7 / Golden Gate, note delle anteprime e beta: https://www.macbartender.com/goldengate/releases/
5. MacStories, Niléane, "Bartender 5 Is the Essential Menu Bar Upgrade for macOS Sonoma" (ottobre 2023): https://www.macstories.net/reviews/bartender-5-is-the-essential-menu-bar-upgrade-for-macos-sonoma/
6. Bartender 6, pagina di supporto: https://macbartender.com/Bartender6/support
7. Pagina d'acquisto: https://macbartender.com/purchase/
8. ifun.de, "Menüleisten-Manager Bartender für macOS Tahoe optimiert" (15/09/2025): https://www.ifun.de/menueleisten-manager-bartender-fuer-macos-tahoe-optimiert-264954/
9. MacRumors, "Bartender Mac App Under New Ownership…" (04/06/2024): https://www.macrumors.com/2024/06/04/bartender-mac-app-new-owner/
10. TidBITS, "Bartender Developer Explains and Apologizes for Quiet Acquisition" (05/06/2024): https://tidbits.com/2024/06/05/bartender-developer-explains-and-apologizes-for-quiet-acquisition/
11. Brett Terpstra, "Bartender Pro review" (13/05/2026): https://brettterpstra.com/2026/05/13/bartender-pro-review/
12. TheSweetBits, "Bartender 6: The menu bar utility macOS Tahoe still needs": https://thesweetbits.com/tools/bartender/
13. ifun.de su Ice e Thaw 2.0: https://www.ifun.de/thaw-2-0-ist-da-freier-menueleistenmanager-fuer-macos-26-288052/ ; Ice: https://github.com/jordanbaird/Ice
14. Hidden Bar, Mac App Store e sorgente MIT: https://apps.apple.com/app/id1452453066 , https://github.com/dwarvesf/hidden
15. Apple Community, elenco "Consenti nella barra dei menu" di macOS 26: https://discussions.apple.com/thread/256145886
16. Bartender 4, pagina prodotto (trigger Qualsiasi cambiamento, Icona, Script, Batteria, Wi-Fi, Time Machine; Quick Search e Spotlight): https://www.macbartender.com/Bartender4/
17. Setapp, "Quick reveal. Set triggers for when to show menu items": https://setapp.com/app-articles/bartender-quick-reveal
18. Six Colors su Bartender 6 Pro (maggio 2026): https://sixcolors.com/post/2026/05/bartender-6s-new-pro-feature-turns-the-macbook-notch-into-a-dynamic-peninsula/ (citata da ricerca, non letta per intero)
