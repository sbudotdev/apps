# Sbu Klack (nome provvisorio): sintesi su Klack

Klack di Henrik Ruscon (Mac App Store, ID 6446206067): un suono da tastiera meccanica a ogni tasto, nella barra dei menu. 4,99 $ una volta, macOS 15, versione 2.1.4 del 26/05/2026, uscita il 23/03/2023. Virale al lancio (9to5Mac, Product Hunt, "Featured in Forbes"). Un clone a parte, Klakk (ID 6754638652), è gratis con acquisti in-app e 14 pacchetti di suoni "Premium".

Fonti: iTunes Lookup con `entity=macSoftware` (24/11/2026), la scheda dello Store, l'articolo di 9to5Mac del 05/04/2023. `Tools/discover.py` non legge le app Mac (usa `entity=software`) e oggi fallisce sul certificato SSL del Python di python.org; il feed delle recensioni non ne restituisce per le app Mac, quindi qui non ci sono problemi degli utenti presi dalle recensioni.

> **Attenzione al filtro di nicchia (`docs/factory.md`).** Il prezzo è una tantum e basso: nessuna indignazione da abbonamento, come Habits e Noise. Esistono alternative gratis (Mechvibes, open source ma Electron; Klakk con acquisti in-app). Passa come le altre app Mac (Prompter): app nativa, pulita, senza pacchetti a pagamento. Il pubblico è lo stesso di Prompter: chi registra, chi scrive, chi fa video.

## Matrice delle feature

Feature dalla scheda dello Store. Framework: macOS 15, solo Apple.

| Feature | A pagamento? | Sbu | Framework | Conflitto con CLAUDE.md? |
|---|---|---|---|---|
| Suono a ogni tasto, anche nelle altre app | sì (tutta l'app) | core | `CGEvent.tapCreate` in sola lettura (`.listenOnly`) con il permesso Monitoraggio input (`CGRequestListenEventAccess`); funziona nella sandbox, Klack è sul Mac App Store | no; il testo digitato non si legge né si salva, solo il codice del tasto |
| Suono alto fedeltà, latenza minima | sì | core | `AVAudioEngine` con buffer già in memoria, un `AVAudioPlayerNode` per voce | no |
| Pressione e rilascio (down/up) | sì | core | due campioni per tasto | no |
| Altezza leggermente casuale | sì | core | `AVAudioUnitTimePitch` o più varianti per tasto | no |
| Switch diversi (es. blue, brown, red, cream) | sì | core, 3-4 switch | campioni propri, vedi sotto | no |
| Audio spaziale: il tasto suona dalla sua posizione | sì | core | pan stereo per colonna della tastiera, o `AVAudioEnvironmentNode` | no |
| Barra dei menu | sì | core | `MenuBarExtra`, `LSUIElement` | no |
| Regolazione del tono ("tone pad") | sì | nice | EQ (`AVAudioUnitEQ`) | no |
| Automazioni del sonno (silenzio a orari o con lo schermo bloccato) | sì | nice: si zittisce quando lo schermo si blocca o il Mac dorme | `NSWorkspace` notifiche | no |
| Notifiche istantanee | sì | skip | n/d | non serve: nessuna notifica |
| Statistiche d'uso | sì | core come **cifra**: tasti premuti oggi | contatore locale in UserDefaults | no; un solo numero, mai cosa si è scritto |

## Suoni

Non si possono usare i campioni di Klack né di Mechvibes (licenze dei pacchetti miste). Due strade:

1. **Registrati da noi**: una tastiera meccanica vera, un microfono, una cartella di campioni (pressione e rilascio per tasti normali, spazio, invio, backspace). Qualità migliore, mezza giornata di registrazione.
2. **Sintetizzati**: estendere `Tools/make_sounds.py` (oggi solo sinusoidi) con rumore filtrato e risonanze. Nessuna registrazione, ma un clic sintetico rischia di suonare finto, e il suono è il prodotto.

## Rischi tecnici

- **Permesso Monitoraggio input**: senza, l'app non sente i tasti. Il primo avvio lo spiega con una frase e un pulsante, poi apre Impostazioni di Sistema.
- **Campi password**: macOS con Secure Input non manda gli eventi; il suono si ferma lì, ed è giusto così.
- **Latenza**: sotto i 10 ms percepiti. Buffer piccoli e campioni già caricati, niente decodifica al tasto.
- **Mac App Store**: l'app sta nella sandbox, quindi per ADR-0024 va sullo Store (o sul .dmg, a scelta).

## Cosa fa meglio Sbu

- Gratis, tutti gli switch inclusi, nessun pacchetto a pagamento (contro Klakk).
- Nativa e leggera (contro Mechvibes in Electron).
- Una cifra sola, i tasti premuti oggi, chiusa dal punto fermo.
- Nessun testo letto o salvato, solo il conteggio: si dice nella scheda e nel primo avvio.
