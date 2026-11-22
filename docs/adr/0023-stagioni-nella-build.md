# Stagioni nella build, accese dalla data

Le **App Sbu** possono cambiare qualcosa in un periodo dell'anno (la prima è Natale, dal 1/12 al 6/1 compresi). La **Stagione** è scritta nell'app e si accende solo dalla data del telefono, nel suo fuso orario e sui giorni del calendario gregoriano: niente rete, niente download, niente stato salvato. SbuKit la espone come `SbuSeason.active(on:in:)` (funzione pura, data e calendario iniettabili) e come valore d'ambiente `sbuSeason`, che vale la stagione di oggi e si forza con `.environment(\.sbuSeason, .christmas)` in anteprime e test.

Motivo: un interruttore remoto o una stagione scaricata violerebbe le regole di prodotto (niente rete); tenerla nella build la rende verificabile in App Review e uguale per tutte le app. Il costo è che una stagione nuova, o una data spostata, esce solo con un aggiornamento.

Regole: fuori stagione nessuna app cambia aspetto. In stagione un'app cambia solo ciò che la sua decisione approva; un accento di stagione, se serve, va in `Design/tokens.json` come ogni altro colore. Le stagioni non toccano le **Promesse** né le superfici scure (ADR-0011, ADR-0013).
