# ZTL: costruire o no

1 novembre 2026. Da rivedere con Matteo prima di qualsiasi lavoro su `Apps/`.

**Esito: fattibile sulla carta, non ancora provato su strada.** I dati ci sono per una 1.0 parziale. La navigazione con i soli servizi Apple non regge; un grafo OSM nell'app con A* in Swift puro supera la soglia (spike 2). Prima di costruire restano la prova su iPhone e su strada, e il freeze di `docs/stato.md`.

## 1. Copertura dei dati

Dettaglio in `fonti.md`. Non è parere legale, e le geometrie non sono state scaricate, salvo l'XML di Torino.

| Stato | Comuni | Quali |
|---|---|---|
| Licenza aperta dichiarata | 12 | Bergamo, Bologna, Cesena, Ferrara, Firenze, Genova, Milano, Modena, Napoli, Roma, Torino, Trento |
| Da ridisegnare da fonte ufficiale | 5 | Brescia, Padova, Prato, Trieste, Venezia |
| Da chiedere al Comune | 7 | Bari, Catania, Messina, Palermo, Parma, Taranto, Verona |
| Non trovati | 2 | Cuorgnè, Villadossola |

Licenza a posto non vuol dire dato aggiornato:
- **Aggiornati:** Milano (5-10/2026), Firenze (3/2026), Cesena (1/2026).
- **Vecchi:** Genova (3/2018), Bologna (perimetri 8/2021), varchi di Bergamo (9/2016).
- **Da chiarire:** Torino (validità 2022-2024, licenze divergenti) e Roma (licenze disomogenee, layer dal 2018 al 2024).
- **Orari:** solo Torino e Bergamo li hanno nei dati. Altrove vanno trascritti dagli atti.

La parità con i 24 comuni dello screenshot non è raggiungibile subito. La 1.0 dichiara i comuni coperti e dice quando una zona non lo è.

## 2. Spike del routing

Solo `MKDirections`, 20 tragitti, una zona per tragitto, perimetri approssimati a mano. Soglia fissata prima del primo giro: almeno 9 validi su 10 per città, con al massimo +50% di tempo o +10 minuti. Risultati in `Spikes/ZTLRouting/results/`, branch locale `spike/ztl`.

| Giro | Milano Area C | Firenze Centro |
|---|---|---|
| 1, tre tappe per arco | 6/10 | 7/10 |
| 2, tutti i vertici dell'arco | 7/10 | 7/10 |

- Secondo giro: tra i tragitti che nel percorso base attraversano la zona, ne passano 8 su 14. Riescono solo grazie alle alternative proposte da MapKit.
- Le tappe non risolvono: nel secondo giro le 12 varianti provate restano tutte in zona, per 357-2.664 m.
- Stesso input, esiti diversi tra un giro e l'altro (Centrale-Porta Genova, Brera-Bocconi).
- Limiti del test: una zona sola e perimetri imprecisi. Con molte zone piccole, come a Bergamo, il risultato può solo peggiorare.

**Conclusione:** sotto soglia. Non si può promettere una guida che evita le ZTL affidandosi solo a MapKit.

## 3. Manutenzione dei dati

Non misurata. È il costo vero dell'app, e un errore può costare una multa a chi la usa.

Proposta da confermare:
- ogni regola porta fonte e data di verifica;
- controllo periodico di tutti i comuni coperti, con il primo giro cronometrato per stimarne il costo;
- correzioni solo con un aggiornamento dell'app, quindi con i tempi di revisione Apple: una regola scaduta deve far rispondere "non so";
- segnalazioni degli utenti via mail o issue pubblica.

## Spike 2: grafo OSM con A*

Grafo stradale OSM di Milano e Firenze, A* su archi in Swift puro, perimetri ufficiali (Area C; ZTL diurna di Firenze, tre settori; prova di stress con tutte le 237 aree di Milano tranne Area B). Stessi 20 tragitti, stessa soglia. Risultati in `Spikes/ZTLRouting/results/`, branch locale `spike/ztl`.

| Giro | Milano Area C | Firenze | Milano, tutte le aree | Divieti di svolta violati |
|---|---|---|---|---|
| 3, senza divieti di svolta | 10/10 | 8/10 | 8/10 | 6 percorsi su 28 |
| 4, con divieti di svolta | 10/10 | 10/10 | 10/10 | 0 su 30 |

Tra un giro e l'altro è cambiata anche la regola di misura: i settori adiacenti di una ZTL contano come una zona sola per chi parte dentro. Il miglioramento di Firenze dipende da questo e dalla penalità che accorcia l'uscita dalla zona, non solo dalle svolte. Il "partire dentro" a Firenze attraversa altri settori prima di uscire: va verificato sulle regole reali.

Misure sul Mac, build release:
- **Peso:** Milano 4,8 MB (3,3 MB compresso), Firenze 2,3 MB (1,6 MB compresso), con 161.396 e 74.258 nodi. Grafo senza contrazioni: si può ridurre.
- **Tempi:** caricamento sotto i 10 ms, A* da 2 a 60 ms, blocco delle zone 15-102 ms.

Perché non basta:
- **Test poco discriminante:** il percorso libero del grafo entrava in zona solo in 3 tragitti su 10 a Milano Area C e 2 su 10 a Firenze. Il grafo favorisce le circonvallazioni anche senza vincoli.
- **Zero in zona è per costruzione:** l'algoritmo non può entrare. Il controllo geometrico lo conferma, ma vale quanto il perimetro.
- **Zero svolte vietate vale solo rispetto a OSM:** router e controllo usano gli stessi dati. Errori della mappa, sensi unici sbagliati e vie chiuse non si vedono. Nessun percorso è stato guidato.
- **Tempi di arrivo inutilizzabili:** il grafo stima circa la metà di Apple (Milano 80 minuti contro 195 sui 10 tragitti del giro 3, Firenze 99 contro 188), mentre le distanze sono vicine. Servono calibrazione e penalità agli incroci. Traffico assente.
- **Non provati:** iPhone, istruzioni di guida, voce, ricalcolo fuori percorso, CarPlay, raccordo con MapKit fuori dal grafo.
- **Limiti di velocità:** `maxspeed` copre il 34% delle strade a Milano e il 29% a Firenze. La parità con l'originale non è garantita.
- **Zone reali:** in `milano-tutte` i tipi DT e DA sono stati evitati senza leggerne il significato. L'app vera sceglie le zone in base a veicolo e orario, e per Area C deve poter proporre il ticket.

Da accettare in anticipo:
- nessun traffico in tempo reale nel tratto urbano;
- il grafo è un database derivato da OSM: va tenuto in un file separato, pubblicato sotto ODbL, con attribuzione visibile (lettura non legale in `fonti.md`);
- una sola fonte per tipo di dato per comune, per non mescolare OSM e dati comunali.

## Prossima prova

Build sul tuo iPhone con i due grafi, e alcuni tragitti guidati davvero a Milano o Firenze, confrontando con la segnaletica. Se regge, si apre il lavoro sull'app.

## Prima di scrivere l'app

Da approvare prima di scrivere l'app: ADR per la rete verso Apple, entitlement CarPlay navigazione, parere legale su ODbL e CAD art. 52, mappa delle issue. Il freeze di `docs/stato.md` resta valido.
