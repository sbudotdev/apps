# App Mac a pagamento da rifare gratis — ricerca del 24/11/2026

Fonti: classifica «Top Paid» del Mac App Store, tutte le categorie, US e IT (`apps.apple.com/<cc>/mac/charts/36?chart=top-paid`, letta il 24/11/2026 alle 21:30); prezzi dalla search API di iTunes (`entity=macSoftware`, US). Le app vendute fuori dallo Store non hanno classifiche: per loro valgono i prezzi dei siti e delle rassegne, da riverificare sul sito del produttore. L'API non espone il numero di recensioni delle app Mac, quindi la popolarità viene solo dalla posizione in classifica.

## Classifica Top Paid Mac, 24/11

**US (1–25):** Shadowrocket, Logic Pro, Things 3, Jump Desktop, Wipr 2, Keka, Magnet, DaisyDisk, Klack, Noir, FL Studio Mobile, Pixelmator Pro, Final Cut Pro, Dark Reader for Safari, UTM, GrandPerspective, RAR Extractor - Unarchiver Pro, Console Remote, Tampermonkey, Quantumult X, forScore, MainStage, LibreOffice, PhotoSweeper, Scrivener 3.

**IT (1–25):** Logic Pro, RAR Extractor - Unarchiver Pro, Shadowrocket, forScore, LibreOffice, Magnet, MediaInfo, Wipr 2, Keka, MainStage, UTM, Final Cut Pro, Miele-LXIV, Magic Packet (WOL), iReal Pro, Noir, PDF Squeezer 4, Things 3, xSearch for Safari, Whisper Notes, Pixelmator Pro, Upscayl, Just Press Record, Caffeinated, Vinegar.

Klack (9° US) è già rifatta: Sbu Keys.

## Scartate

- **Troppo grandi o professionali**: Logic Pro, Final Cut Pro, MainStage, Pixelmator Pro, Things 3, Scrivener, FL Studio, forScore, iReal Pro, Miele-LXIV.
- **Rete o proxy**: Shadowrocket, Quantumult X, Jump Desktop, Console Remote (vietati dalle regole di prodotto, salvo ADR-0007).
- **Già gratis o open source**: LibreOffice, UTM (gratis fuori dallo Store), Keka (gratis dal sito), Tampermonkey, Upscayl, Amphetamine.
- **Rischio legale o dipendenze**: RAR Extractor (serve un decoder RAR proprio, la libreria unrar è una dipendenza di terze parti), Vinegar e xSearch (dipendono da YouTube e dai motori di ricerca).
- **Troppe funzioni per la parità**: CleanShot X (29 $ una tantum o 8 $/mese), Bartender (vedi sotto).

## Candidate

| App originale | Prezzo | Classifica 24/11 | Cosa fa | Alternativa gratis già esistente | Sandbox / Mac App Store | Note per Sbu |
|---|---|---|---|---|---|---|
| **DaisyDisk** (+ GrandPerspective) | 9,99 $ (2,99 $) | US 8 (US 16) | mappa dello spazio occupato sul disco | GrandPerspective gratis da SourceForge, OmniDiskSweeper | sì, con la cartella scelta dall'utente o l'Accesso completo al disco | la cifra Quaderno è naturale: i GB liberi. Gemella di Sbu Clean |
| **Magnet** | 4,99 $ | US 7, IT 6 | finestre a metà, a quarti, a tutto schermo con scorciatoie | Rectangle (open source) | sì, Magnet è sullo Store (Accessibilità) | in classifica da anni in tutti e due i Paesi |
| **PDF Squeezer 4** | 19,99 $ | IT 17 | comprime i PDF | Anteprima con il filtro Quartz, di qualità bassa | sì (PDFKit, Quartz) | prezzo alto e una cosa sola, gemella di Sbu Shrink |
| **Wipr 2** | 4,99 $ | US 5, IT 8 | blocca pubblicità e tracker in Safari | AdGuard e uBlock Origin Lite (gratis) | sì (estensione Safari di blocco contenuti) | coerente con la promessa «nessuna pubblicità»; le liste di filtri hanno licenze (EasyList GPL/CC BY-SA) e si aggiornano solo con l'app, senza rete. Può andare anche su iPhone |
| **Noir / Dark Reader** | 3,99 $ / 4,99 $ | US 10 e 14, IT 16 | tema scuro su ogni sito in Safari | Dark Reader è open source su altri browser | sì (estensione Safari) | piccola, ma sono due app in classifica sullo stesso bisogno |
| **TextSniper** | 5,99 $ | — | seleziona una zona dello schermo e ne copia il testo (OCR) | Testo attivo di macOS solo nelle immagini | sì (permesso Registrazione schermo, Vision sul dispositivo) | piccola come Klack, si fa in una settimana |
| **PhotoSweeper** | 14,99 $ | US 24 | foto doppie e simili sul Mac | nessuna diffusa | sì (PhotoKit) | il cuore di Sbu Clean, portato sul Mac con SbuKit |
| **Just Press Record** | 6,99 $ | IT 23 | registra e trascrive sul dispositivo | Memo Vocali, con la trascrizione solo dalle versioni recenti | sì (Speech) | anche iPhone e Watch: è più grande |
| **Bartender** | 20 $ una tantum, Pro 15 $/anno (prezzi da rassegne) | fuori dallo Store | nasconde e ordina le icone nella barra dei menu | Ice, Hidden Bar (open source) | parziale: Hidden Bar sta sullo Store con un separatore, la parità completa con Bartender (ordinare, nascondere icone di altri) richiede Accessibilità e Registrazione schermo, quindi Developer ID come Sbu Seasons | .dmg ufficiale scaricato il 24/11 per provarlo da utente; Ice gratis toglie la notizia |
| **iStat Menus** | 11,99 $ | fuori dalla top 25 | sensori, CPU, rete nella barra dei menu | Stats (open source) | sì, versione Store esistente | l'alternativa gratis è già molto conosciuta |

## Raccomandazione

1. **DaisyDisk → Sbu Disk** (nome provvisorio). È in classifica in US con due app che fanno la stessa cosa (DaisyDisk e GrandPerspective). La cifra del design system c'è già (i GB liberi). Sta nella sandbox e quindi sul Mac App Store. Nessuna alternativa gratis è altrettanto curata.
2. **Magnet → Sbu Windows** (nome provvisorio). È l'unica utility in classifica alta sia in US sia in IT. Rectangle esiste, ma chi compra Magnet sullo Store non lo trova.
3. **PDF Squeezer → Sbu Shrink per il Mac**. Costa 19,99 $ e fa una cosa sola: comprime i PDF. Il nome è da decidere con Shrink.

Da tenere in coda: Wipr 2 (forte per il messaggio «nessuna pubblicità», ma ha più lavoro sulle licenze dei filtri) e TextSniper (il lavoro più veloce).

Tutte le specifiche nascono da dati pubblici (`Tools/spec.py`, pagine del produttore, prova dell'app da utente): niente decompilazione o estrazione di asset.
