# ZTL: costruire o no

1 novembre 2026. Da rivedere con Matteo prima di qualsiasi lavoro su `Apps/`.

**Esito: non ancora.** I dati ci sono per una 1.0 parziale. La navigazione con i soli servizi Apple non regge. Prima di costruire serve un secondo spike, con un grafo stradale nell'app.

## 1. Copertura dei dati

Dettaglio in `fonti.md`. Non è parere legale, e le geometrie non sono state scaricate, salvo l'XML di Torino.

| Stato | Comuni | Quali |
|---|---|---|
| Licenza aperta dichiarata | 11 | Bergamo, Bologna, Cesena, Ferrara, Firenze, Genova, Milano, Modena, Roma, Torino, Trento |
| Da ridisegnare da fonte ufficiale | 6 | Brescia, Napoli, Padova, Prato, Trieste, Venezia |
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

## Prossimo passo proposto: spike 2

Grafo stradale OSM di Milano e Firenze nel bundle, A* in Swift puro, zone escluse dal grafo. Stessi 20 tragitti e stessa soglia, ma con i perimetri ufficiali di Milano e Firenze.

Da misurare:
- dimensione del grafo nel bundle e tempi di calcolo su iPhone;
- qualità del percorso rispetto a MapKit;
- come unire il tratto urbano al resto del viaggio, che fuori città può restare su MapKit;
- quante vie hanno `maxspeed`: il limite di velocità mostrato dall'originale non arriva da MapKit.

Da accettare in anticipo:
- nessun traffico in tempo reale nel tratto urbano;
- il grafo è un database derivato da OSM: va tenuto in un file separato, pubblicato sotto ODbL, con attribuzione visibile (lettura non legale in `fonti.md`);
- una sola fonte per tipo di dato per comune, per non mescolare OSM e dati comunali.

Se anche lo spike 2 fallisce, la parità sulla navigazione non è raggiungibile con le regole Sbu. Resterebbe da decidere se fare un'app senza guida interna o con una dipendenza di terzi, che oggi è vietata.

## Se lo spike 2 passa

Da approvare prima di scrivere l'app: ADR per la rete verso Apple, entitlement CarPlay navigazione, parere legale su ODbL e CAD art. 52, mappa delle issue. Il freeze di `docs/stato.md` resta valido.
