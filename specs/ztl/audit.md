# Audit a scatola nera di ZigZag

Per Matteo, sulla sua copia dell'app (bastano 3 giorni di prova per le funzioni Pro). Si annota solo il comportamento: cosa fa l'app e quando. Niente testi, grafica, dati ZTL copiati, né analisi del binario o del traffico (ADR-0003). Ricorda di disdire la prova.

Primo giro: 1/11/2026, versione 0.4.14 (93), due registrazioni dello schermo senza audio (circa 5 minuti), veicolo fermo nell'hinterland di Milano. Le registrazioni contengono dati personali e restano fuori dal repo. `[x]` risposto, `[~]` risposto in parte, `[ ]` non provato.

## Copertura
- [~] Quali dei 24 comuni dello screenshot hanno davvero zone sulla mappa? La descrizione ne nomina solo 11.
  - Milano ha zone sulla mappa. L'elenco dei permessi parte da Bari e Bergamo; non è stato sfogliato oltre.
  - Le segnalazioni pubbliche indicano zone mancanti a Cremona, Sorrento, Cormano e Verona. Il conteggio resta da fare.
- [~] Cosa mostra un comune coperto senza ZTL? E uno fuori copertura?
  - Un percorso che esce dalla copertura si calcola lo stesso, con un avviso prima della partenza e una riga fissa durante la guida: le ZTL note sono controllate, le altre restrizioni no.
  - Il comune coperto senza ZTL non è stato provato.

## Verifica
- [~] Quali esiti esistono (vietato, condizioni, consentito, altro) e quando l'app dichiara di non sapere?
  - Visti solo consentito e vietato, e solo in esempi illustrativi. Mappa e scheda della destinazione cambiano colore in base al veicolo, ma la scheda reale non è stata aperta.
- [x] Quali campi chiede il veicolo? Quali permessi si possono dichiarare?
  - Soprannome (massimo 40 caratteri), tipo (auto, moto, ciclomotore), targa (massimo 12).
  - Dalla targa, digitata o letta da foto, l'app ricava alimentazione, classe Euro e CO2 (facoltativa). Tutti i campi si correggono in una schermata di riepilogo. Esiste l'inserimento manuale.
  - Il veicolo si può rimandare durante l'introduzione.
  - Permesso: si sceglie il veicolo, poi la ZTL da un elenco per comune. I passi successivi non sono stati aperti.
- [ ] Come tratta festivi e deroghe?

## Calendario del veicolo (Pro)
- [ ] Che forma ha: griglia, lista, per zona o per città? Quanto avanti arriva?

## Navigazione (Pro)
- [~] Destinazione dentro una ZTL vietata: cosa propone? Dove ti lascia?
  - Duomo di Milano, due tentativi: attesa (la prima volta circa 29 s), poi errore generico senza alternative e senza punto di arrivo proposto. Dopo l'errore la finestra di attesa resta a schermo.
  - Porta Venezia, appena fuori dall'Area C, ha risposto in circa 3 s dallo stesso punto. Il legame con la destinazione è probabile ma non provato: serve un altro tentativo, anche con un altro veicolo.
- [ ] Partenza dentro una ZTL: cosa fa?
- [~] Cosa succede se esci dal percorso? Quanto ricalcola?
  - Non provato in movimento. A veicolo fermo la riga di stato passa da avvio a ricalcolo a segnale GPS debole con percorso mantenuto; tempo e km non cambiano.
- [~] Quali tipi di zona evita, e quali lascia sul percorso con un avviso?
  - Il percorso provato gira attorno al centro e arriva al bordo dell'Area C. Nessun avviso di zona sul percorso, solo quello di copertura. Serve un tragitto che attraversi una zona.
- [~] Istruzioni vocali: in quali momenti? Limite di velocità: sempre presente?
  - Pulsante audio presente, nessun audio registrato. Il limite compare pochi secondi dopo l'avvio, non subito.
- [ ] CarPlay: quali controlli ci sono?

## Altro
- [~] Parcheggi: cosa si vede, cosa si modifica, si vede cosa hanno modificato gli altri?
  - Interruttore nelle impostazioni, spento di default. Non provato.
- [~] Segnalazioni: quali campi, dove finiscono?
  - Finiscono in un elenco pubblico con ricerca, filtri per stato e comune, stato di verifica, voti e commenti. Il modulo di invio non è stato aperto.
  - C'è anche una classifica pubblica dei comuni richiesti, con voti: in testa Pisa, Monza, Reggio Emilia.
- [ ] Cosa funziona senza connessione?

## Osservato fuori dalla lista

- **Paywall:** arriva subito dopo l'introduzione e il veicolo, prima della mappa. Nel tempo in cui è rimasto a schermo non si vede un modo per chiuderlo. Va riprovato senza acquistare.
- **Primo avvio:** dopo l'acquisto, giro guidato su un esempio con veicolo fittizio (destinazione, risposta, veicolo, orario), poi coriandoli.
- **Mappa:** selettori di orario e veicolo sempre in alto, livelli, posizione. Sotto: ricerca (anche vocale), preferiti, elenco ZTL, recenti. Mapbox e OSM sono citati come fonti.
- **Zone a Milano:** oltre ai perimetri compaiono moltissimi tratti di singole vie, in più colori. È un caso vicino a `milano-tutte` dello spike 2, non al solo perimetro. La legenda non è stata aperta.
- **Scheda del luogo:** nome, distanza, indirizzo, salva, condividi, altro; le ZTL del punto con l'esito; regole per sezioni. Le regole risultano scritte in italiano, con un avviso quando manca la traduzione.
- **Anteprima del percorso:** tempo, km, veicolo, avviso di copertura, avvio. Nessuna alternativa di percorso visibile. All'avvio c'è un controllo del percorso con attesa. La partenza è indicata come approssimativa finché la posizione non è precisa.
- **Guida:** manovra con distanza, limite, audio, riga di stato, tempo in verde, km, ora di arrivo, chiusura. Spostando la mappa compare un comando per tornare a seguire il percorso.
- **Impostazioni:** account facoltativo (non serve per comprare), abbonamento, veicoli, permessi, idee, segnalazioni, contributi, comuni richiesti, bug, supporto, recensione, nord in alto, edifici 3D, parcheggi, aspetto, lingua (vale al riavvio), posizione, rivedi introduzione, privacy, termini.

## Cosa cambia per lo spec

1. **Dati dalla targa:** richiedono un servizio esterno, in conflitto con le regole di prodotto. Deciso il 1/11: in Sbu il veicolo si compila a mano.
2. **Destinazione in zona vietata:** è il punto debole osservato dell'originale. Lo spec deve dire dove ti lascia Sbu: ultimo punto consentito e tratto finale a piedi.
3. **Tratti di singole vie:** il dato da mantenere è più vasto dei perimetri comunali. Il censimento in `fonti.md` va riletto con questo in mente.
4. **Segnalazioni e comuni richiesti:** richiedono un server condiviso. Resta la proposta di `decisione.md` (mail o issue pubblica); la parità piena non è possibile senza eccezione.
5. **Da aggiungere allo spec:** partenza approssimativa, riga di stato con GPS debole, avviso di copertura prima e durante la guida, comando per tornare al percorso.

## Secondo giro: cosa registrare

1. Scheda completa del Duomo: esito, regole, cambio di orario, calendario del veicolo.
2. Duomo di nuovo, per confermare l'errore, e una destinazione dentro un'altra ZTL.
3. In auto: partenza dentro una ZTL, uscita dal percorso, voce, CarPlay.
4. Tragitto che attraversa una zona, per vedere cosa evita e cosa segnala.
5. Permesso e segnalazione fino all'ultimo passo prima dell'invio, parcheggi attivi, legenda dei livelli.
6. Modalità aereo. Un comune fuori copertura e uno coperto senza ZTL.
7. Festivi: orario spostato su una domenica e su un giorno festivo.
8. Paywall da reinstallazione, senza acquistare: si può chiudere?
