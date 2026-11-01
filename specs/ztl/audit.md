# Audit a scatola nera di ZigZag

Per Matteo, sulla sua copia dell'app (bastano 3 giorni di prova per le funzioni Pro). Si annota solo il comportamento: cosa fa l'app e quando. Niente testi, grafica, dati ZTL copiati, né analisi del binario o del traffico (ADR-0003). Ricorda di disdire la prova.

## Copertura
- [ ] Quali dei 24 comuni dello screenshot hanno davvero zone sulla mappa? La descrizione ne nomina solo 11.
- [ ] Cosa mostra un comune coperto senza ZTL? E uno fuori copertura?

## Verifica
- [ ] Quali esiti esistono (vietato, condizioni, consentito, altro) e quando l'app dichiara di non sapere?
- [ ] Quali campi chiede il veicolo? Quali permessi si possono dichiarare?
- [ ] Come tratta festivi e deroghe?

## Calendario del veicolo (Pro)
- [ ] Che forma ha: griglia, lista, per zona o per città? Quanto avanti arriva?

## Navigazione (Pro)
- [ ] Destinazione dentro una ZTL vietata: cosa propone? Dove ti lascia?
- [ ] Partenza dentro una ZTL: cosa fa?
- [ ] Cosa succede se esci dal percorso? Quanto ricalcola?
- [ ] Quali tipi di zona evita, e quali lascia sul percorso con un avviso?
- [ ] Istruzioni vocali: in quali momenti? Limite di velocità: sempre presente?
- [ ] CarPlay: quali controlli ci sono?

## Altro
- [ ] Parcheggi: cosa si vede, cosa si modifica, si vede cosa hanno modificato gli altri?
- [ ] Segnalazioni: quali campi, dove finiscono?
- [ ] Cosa funziona senza connessione?
