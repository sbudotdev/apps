# ZTL: protocollo della prova su strada

14 novembre 2026. È la "Prossima prova" di `decisione.md`: l'app su iPhone, tragitti guidati davvero, confronto con la segnaletica. La prova la fai tu; questo file dice dove andare, cosa guardare e cosa scrivere.

**Domanda a cui risponde:** il grafo OSM con A* regge fuori dal Mac? Se sì, si apre il lavoro sull'app; se no, si scrive cosa si è rotto.

## Regola zero: niente multe

- **Non entrare mai in una zona attiva per provare l'app.** Se l'app ti porta verso un varco acceso, ti fermi prima, lo annoti e prendi un'altra strada. Quel tragitto è fallito, non serve finirlo.
- "Partenza dentro" solo quando la zona è spenta: l'app dice che è spenta **e** il pannello al varco dice "non attivo". Altrimenti salti quei tragitti.
- Il telefono sta sul supporto. Le note le prende chi è accanto a te, oppure le detti a voce (Memo vocali) e le trascrivi a fine giro. Mai scrivere mentre guidi.

## Prima di partire

1. **Build Debug da Xcode**, non TestFlight: la registrazione delle tracce GPS (`TraceRecorder`) e la sezione "Prova su strada" nelle impostazioni esistono solo in Debug.
   ```sh
   cd Apps/SbuZTL && xcodegen && open SbuZTL.xcodeproj
   ```
   Schema `SbuZTL`, configurazione Debug, il tuo iPhone come destinazione, Run. Annota il commit (`git rev-parse --short HEAD`).
2. Posizione: "Mentre usi l'app", con **Posizione esatta** attiva.
3. Imposta il veicolo vero (alimentazione, Euro) nell'app: il verdetto delle zone dipende da quello.
4. Voce accesa, volume alto, telefono in carica.
5. Stampa o tieni aperta la tabella di annotazione qui sotto.

## Città e tragitti

Prima **Milano**, poi **Firenze**: sono le due città del test sul Mac, quindi i risultati si confrontano. Bologna, Roma e Torino sono facoltative: se hai tempo, un tragitto "attraversa" e un "arrivo dentro" per città.

I tragitti sono un sottoinsieme dei 20 dello spike (`spike/ztl`, `Spikes/ZTLRouting/results/run4-grafo-svolte.md`), scelti perché mettono alla prova casi diversi. I tempi sono quelli stimati dal grafo, utili per il confronto.

### Milano (Area C e aree pedonali)

| # | Tragitto | Caso | Stima del grafo |
|---|---|---|---|
| M1 | Porta Venezia → Ticinese | il percorso libero entrerebbe in Area C: l'app deve aggirarla | 7 min, 5,4 km |
| M2 | Centrale → Duomo | arrivo dentro: parcheggio fuori e tratto a piedi (circa 1,2 km) | 5 min, 3,3 km |
| M3 | Bocconi → Castello | arrivo dentro, lato opposto (a piedi circa 670 m) | 7 min, 5,7 km |
| M4 | Lambrate → San Siro | tragitto lungo, circonvallazioni, aree pedonali vicino a San Siro | 16 min, 11,3 km |
| M5 | Brera → Bocconi | partenza dentro, solo con Area C spenta | 10 min, 7,2 km |

### Firenze (ZTL diurna, tre settori)

| # | Tragitto | Caso | Stima del grafo |
|---|---|---|---|
| F1 | Campo di Marte → Duomo | arrivo dentro (a piedi circa 735 m) | 7 min, 4,7 km |
| F2 | Novoli → Santa Croce | arrivo dentro, passa vicino ai settori | 10 min, 7,8 km |
| F3 | Libertà → San Frediano | viali e Oltrarno, vicino al confine | 6 min, 4,5 km |
| F4 | Novoli → Gavinana | tragitto lungo, attraversa la città fuori dalla ZTL | 15 min, 10,7 km |
| F5 | Santo Spirito → Campo di Marte | partenza dentro, solo con la ZTL spenta: attraversa altri settori prima di uscire (da verificare, vedi `decisione.md`) | 11 min, 7,2 km |

Fai almeno un tragitto per città **due volte a orari diversi** (uno con la zona accesa, uno spenta) per vedere se il percorso cambia come deve.

## Prove extra durante il giro

- **Fuori percorso:** su M4 o F4 sbaglia apposta una svolta in un punto sicuro. Annota dopo quanti secondi l'app dice "Percorso ricalcolato" e se il nuovo percorso evita ancora le zone.
- **Varchi:** fermati (dove si può) vicino a 2-3 varchi per città. Confronta il verdetto dell'app sulla zona (accesa o spenta, puoi entrare o no) con il pannello luminoso del varco. Foto del pannello, con ora.
- **Limiti di velocità:** il dato OSM copre circa un terzo delle strade. Quando vedi un cartello, confronta con il limite mostrato dall'app.

## Cosa annotare

Una riga per tragitto. Scrivi solo quello che vedi; il perché lo cerchiamo dopo.

| Campo | Cosa scrivere |
|---|---|
| Tragitto e ora | `M1`, data e ora di partenza |
| Zona accesa? | secondo l'app, e secondo il pannello se ne hai visto uno |
| Tempo vero / stimato | minuti reali all'arrivo, minuti promessi dall'app alla partenza |
| Entrata in zona | no / sì (dove) / quasi (ti sei fermato prima del varco: dove) |
| Svolte impossibili | ogni svolta indicata che la segnaletica vieta: incrocio e tipo di divieto |
| Strade sbagliate | sensi unici contrari, strade chiuse, cantieri, strade che non esistono |
| Istruzioni e voce | istruzione arrivata tardi, sbagliata, nome della via sbagliato, voce muta |
| Ricalcolo | quante volte, dopo quanto, se il nuovo percorso era sensato |
| Arrivo dentro | il parcheggio proposto esiste ed è raggiungibile? tratto a piedi sensato? |
| Limite di velocità | differenze tra app e cartelli |
| Altro | qualunque cosa ti abbia fatto dubitare dell'app |

Per ogni problema scatta una foto (cartello, incrocio, schermo dell'app) appena sei fermo in sicurezza.

## Dopo ogni giro

1. Impostazioni dell'app → **Prova su strada**: condividi i file `.csv` delle tracce sul Mac (AirDrop).
2. Le tracce contengono le tue posizioni: **non vanno nella repo**, che è pubblica. Tienile in una cartella fuori da git, per esempio `~/dev/sbudotdev/ztl-tracce/<città>/`, con il nome del tragitto nel file.
3. Le note e le foto vanno nel ticket della prova (sono private), non qui.

## Quando la prova è passata

Stessa soglia dello spike (`decisione.md`), più quello che sul Mac non si poteva vedere:

- **zero entrate in una zona accesa** e zero "quasi" su tutti i tragitti guidati;
- **zero svolte vietate dalla segnaletica**; una via sbagliata in OSM si annota e si corregge, ma due o più sullo stesso tragitto fanno fallire il tragitto;
- almeno **9 tragitti validi su 10**, con al massimo +50% di tempo o +10 minuti rispetto alla stima (la stima del grafo è nota per essere ottimista: il dato serve a calibrarla);
- verdetto dell'app uguale al pannello in **tutti** i varchi controllati: un verdetto sbagliato è una multa;
- il ricalcolo fuori percorso arriva entro 30 secondi e resta fuori dalle zone.

Se la prova non passa, nessuna correzione al volo: si scrive l'esito in `decisione.md` e si decide con te.

## Cosa non copre

CarPlay (manca l'entitlement), traffico in tempo reale (non c'è per scelta), le città oltre Milano e Firenze in modo sistematico, la calibrazione dei tempi (si fa dopo, con le tracce raccolte qui).
