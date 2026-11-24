# App Mac a pagamento da rifare gratis — ricerca del 24/11/2026

Solo app **native per Mac**: le app iPhone/iPad che girano anche sul Mac (nelle classifiche Mac ce ne sono molte: Shadowrocket, forScore, FL Studio Mobile, Wipr 2, Dark Reader…) sono escluse.

Fonti: classifiche «Top Paid» del Mac App Store, 24/11/2026 sera, US e IT, per categoria: Utility (6002), Produttività (6007), Sviluppatori (6026), Foto e video (6008), Grafica (6027), Business (6000), Musica (6011) e la generale (36), da `apps.apple.com/<cc>/mac/charts/<genere>?chart=top-paid`. App nativa = `kind: mac-software` nella lookup API di iTunes; prezzi in dollari dalla lookup US. L'API non espone il numero di recensioni delle app Mac: la domanda si misura con la posizione e con quante app a pagamento fanno la stessa cosa. Le app vendute solo fuori dallo Store (Bartender, CleanShot X, BetterTouchTool) non hanno classifiche.

## La domanda, per bisogno

Un bisogno con più app a pagamento in classifica è un segnale più forte di una sola app alta.

| Bisogno | App a pagamento in classifica (posizione nella categoria) | Prezzi | Alternativa gratis | Note per Sbu |
|---|---|---|---|---|
| **Finestre a metà e a quarti** | Magnet (US Prod. 2, IT Prod. 2), BetterSnapTool (US Prod. 10), Moom Classic (US Util. 25) | 4,99 $, 1,99 $, 6,99 $ | Rectangle (open source, fuori dallo Store) | tre app pagate sullo stesso bisogno; sullo Store (Accessibilità) |
| **Foto e file doppi** | PhotoSweeper (US Foto 2, IT Foto 5), Duplicate Photos Fixer Pro (IT Foto 23), Duplicate File Finder Pro (US Util. 17), Duplicate Manager Pro (US e IT Business), Duplicate Cleaner Pro (IT Business 6) | 14,99 $, 14,99 $, 27,99 $, 5,99 $, 2,99 $ | nessuna diffusa | il gruppo più numeroso; è Sbu Clean portata sul Mac con SbuKit |
| **Spazio su disco** | DaisyDisk (US Util. 4, IT Util. 14), GrandPerspective (US Util. 7, IT Util. 18) | 9,99 $, 2,99 $ | GrandPerspective gratis da SourceForge | la cifra Quaderno è i GB liberi; sandbox con la cartella scelta o l'Accesso completo al disco |
| **Annotare lo schermo e evidenziare il cursore** | Presentify (US Prod. 15), DemoPro (US Prod. 21), Pro Mouse (IT Prod. 10) | 14,99 $, 3,99 $, 7,99 $ | nessuna diffusa | stesso pubblico di Sbu Prompter (chi presenta e registra) |
| **Comprimere e sistemare PDF** | PDF Squeezer 4 (IT Prod. 3), PDF Toolkit+ (IT Prod. 24) | 19,99 $, 1,99 $ | Anteprima con il filtro Quartz, di qualità bassa | prezzo alto e una cosa sola; PDFKit; gemella di Sbu Shrink |
| **Testo da una zona dello schermo (OCR)** | TextSniper (US Prod. 11, IT Prod. 20) | 5,99 $ | Testo attivo, solo nelle immagini | Vision sul dispositivo; lavoro piccolo, come Klack |
| **Safari scuro** | Noir (US Util. 6, IT Util. 7) | 3,99 $ | Dark Reader (open source su altri browser) | estensione Safari, nessuna rete |
| **Monitor di sistema e barra dei menu** | iStat Menus 7 (IT Util. 20), iBar Pro (IT Util. 23), Bartender (fuori dallo Store, 20 $ circa) | 11,99 $, 9,99 $ | Stats, Ice (open source) | alternative gratis già note |
| **Cuffie Bluetooth dalla barra dei menu** | ToothFairy (IT Util. 12) | 6,99 $ | nessuna diffusa | una cosa sola; IOBluetooth, sta sullo Store |
| **Taglia e incolla i file nel Finder** | Command X (US Util. 19, IT Util. 16), PowerClick (US Util. 10, barra nel clic destro del Finder) | 4,00 $, 9,99 $ | nessuna | estensioni del Finder, lavoro piccolo |
| **Tag di MP3 e audio** | Mp3tag (US Musica 6), Metadatics (IT Musica 6) | 24,99 $, 14,99 $ | Mp3tag è gratis su Windows | prezzo alto; AVFoundation |
| **Info su un file video** | MediaInfo (US Util. 11, IT Util. 3) | 0,99 $ | MediaInfo è open source | costa poco: poca notizia |

## Scartate

- **Professionali o troppo grandi**: Logic Pro, Final Cut Pro, Motion, Compressor, MainStage, Pixelmator Pro, DaVinci Resolve Studio, Things 3, Scrivener, iA Writer, PDF Expert, GraphicConverter, Snagit.
- **Già gratis o open source**: Keka, LibreOffice, UTM, Upscayl, Maccy, LosslessCut, System Color Picker (tutte gratis fuori dallo Store), Amphetamine e Caffeinated (Amphetamine è gratis).
- **Rete o desktop remoto**: Jump Desktop, Tailscale, VPN.
- **Rischio o dipendenze**: RAR Extractor e unRAR Pro (serve un decoder RAR proprio), Antivirus.
- **Troppo di nicchia**: ShutterCount, RailModeller, Mocha TN5250, MDB/Access viewer.

Già rifatte: Klack (US Util. 5) è Sbu Keys; NotchPrompter (US Prod. 17) è il genere di Sbu Prompter.

## Raccomandazione

1. **Foto e file doppi sul Mac.** Cinque app a pagamento in classifica, fino a 27,99 $. Il motore c'è già in Sbu Clean: è la più veloce da portare e la più forte come domanda.
2. **Finestre (Magnet).** Tre app a pagamento sullo stesso bisogno, Magnet seconda in Produttività sia in US sia in IT. Rectangle è gratis ma non sta sullo Store.
3. **Spazio su disco (DaisyDisk).** Due app in classifica in tutti e due i Paesi, e la cifra Quaderno più naturale di tutte (i GB liberi).

Subito dopo: annotare lo schermo (Presentify), da lanciare insieme a Sbu Prompter, e PDF Squeezer (19,99 $, terza in Produttività in Italia).

Tutte le specifiche nascono da dati pubblici (`Tools/spec.py`, pagine del produttore, prova dell'app da utente): niente decompilazione o estrazione di asset.
