# Stato di sbu.dev — 22 novembre 2026

Fotografia del 22/11 alle 17:00. Gli stati App Store Connect sono letti dall'API (chiave `ASC_*`, sola lettura) il 22/11; il resto viene dai ticket indicati riga per riga. Sostituisce la versione del 18/10.

## In una frase

Il 22/11 Apple ha sbloccato quattro delle sei app respinte il 14/10: sullo Store ora ci sono 7 app, e 3 aggiornamenti sono in revisione. Restano fuori Habits (Apple offre una telefonata) e Speed. Da qui in avanti esce un'app nuova a settimana, secondo il calendario approvato da Matteo.

## 1. Sullo Store oggi

| App | Versione in vendita (build) | Fonte |
|---|---|---|
| Sbu Subscriptions | **2.1.0** (7) | API ASC 22/11 |
| Sbu Scanner | **2.0.1** (4) | API ASC 22/11 |
| Sbu Find | **1.0** (3) | API ASC 22/11 |
| Sbu Moon | **1.0** (2), approvata il 22/11 | [SBU-264](/SBU/issues/SBU-264), [SBU-271](/SBU/issues/SBU-271), API ASC 22/11 |
| Sbu Clean | **1.1** (7), approvata il 22/11 | [SBU-264](/SBU/issues/SBU-264), [SBU-271](/SBU/issues/SBU-271), API ASC 22/11 |
| Sbu Level | **1.1** (3), approvata il 22/11. È ancora il binario 1.0: le funzioni 1.1 arrivano con la 1.2 | [SBU-264](/SBU/issues/SBU-264), [SBU-270](/SBU/issues/SBU-270), API ASC 22/11 |
| Sbu Noise | **1.0** (3), approvata il 22/11 | [SBU-264](/SBU/issues/SBU-264), [SBU-271](/SBU/issues/SBU-271), API ASC 22/11 |

Fuori dallo Store: **Sbu Seasons** (Mac) **2.3.0** (13), .dmg notarizzato, release GitHub `v2.3.0` del 22/11, pagina sbu.dev/seasons ([SBU-246](/SBU/issues/SBU-246)).

## 2. In revisione

Inviate il 22/11 con l'ok di Matteo ([SBU-270](/SBU/issues/SBU-270)). Sono aggiornamenti con icona e screenshot nuovi: non occupano lo slot settimanale.

| App | Versione (build) | Stato ASC (API 22/11) |
|---|---|---|
| Sbu Moon | 1.1 (4) | WAITING_FOR_REVIEW |
| Sbu Level | 1.2 (7) | WAITING_FOR_REVIEW |
| Sbu Noise | 1.1 (5) | WAITING_FOR_REVIEW |

## 3. Tutte le altre app, una riga ciascuna

Ogni app è su `main`, tranne ZTL. "Prossimo passo" è l'unica cosa che sblocca l'app.

### Ancora respinte

| App | ASC (API 22/11) | Prossimo passo | Fonte |
|---|---|---|---|
| Habits | 1.0 (5) REJECTED, guideline 4.3 | Il 22/11 Apple ha offerto una telefonata con App Review e Matteo l'ha accettata (pomeriggi feriali). Nello stesso messaggio ha chiesto perché le altre quattro sì e Habits no. Si aspetta la chiamata. Il piano B (build nuova con nota "could a human look at this app?") è pronto ma fermo | [SBU-263](/SBU/issues/SBU-263) |
| Speed | 1.1 (2) REJECTED, stato del 14/10 | Nessuna notizia da Apple. Matteo ci aggiorna lui | API ASC 22/11, [SBU-264](/SBU/issues/SBU-264) |

### Pronte su ASC, non inviate

| App | ASC (API 22/11) | Manca | Fonte |
|---|---|---|---|
| Chats | 1.0 PREPARE_FOR_SUBMISSION, build 2 agganciata | build 4 da `main` con icona, screenshot e descrizione nuovi (in corso); poi App Privacy e prova insieme via cavo (Matteo) | [SBU-276](/SBU/issues/SBU-276) |
| Fuel | 1.0 PREPARE_FOR_SUBMISSION, build 2 agganciata | idem | [SBU-276](/SBU/issues/SBU-276) |
| Prompter (Mac + iPhone) | record creato il 22/11 (Apple ID 6837935605), 1.0 macOS e iOS PREPARE_FOR_SUBMISSION, nessuna build | build, screenshot, note per App Review (ancora in bozza). Per ora è distribuita su GitHub | [SBU-251](/SBU/issues/SBU-251) |
| Inventory | 1.0 PREPARE_FOR_SUBMISSION, build 2 | foto di esempio per gli screenshot, App Privacy, prova insieme | API ASC 22/11 |
| ZTL | 1.0 PREPARE_FOR_SUBMISSION, nessuna build (record del 01/11) | vive sul branch `app/ztl` | API ASC 22/11 |

### Scritte, mai su ASC

| App | Manca |
|---|---|
| Shrink, Grid, Tidy, Libretto | test sul device, record ASC, TestFlight |
| Meds | test del task in background sul device, record ASC, TestFlight |
| Remote | prova su una TV vera, richiesta entitlement multicast (Matteo, `docs/remote-multicast-entitlement.md`), conferma delle scelte provvisorie, record ASC |
| Squares (primo Gioco) | prova completa, screenshot Store, record ASC; invio previsto il 7/12 ([SBU-275](/SBU/issues/SBU-275)) |

### Pianificate, non iniziate

Cycle, Cast, Image, Gif, Tags, Knit, Chores, Reader, Exposure.

## 4. Calendario degli invii

Approvato da Matteo il 22/11 ([SBU-275](/SBU/issues/SBU-275)). Un'app nuova a settimana. **Ogni invio va approvato a parte.**

| Settimana | App |
|---|---|
| 23/11 | Sbu Chats |
| 30/11 | Sbu Fuel |
| 7/12 | Sbu Squares (primo gioco) |
| 14/12 | Sbu Prompter (Mac + iPhone) |
| poi | Inventory, poi Shrink, Grid, Tidy, Libretto, Meds |

Metà dicembre: lancio della collezione (Show HN + Product Hunt), dal piano del 18/10.

## 5. Bloccanti, in ordine di peso

1. **Il test insieme via cavo** manca a Chats e Fuel, ed è il prossimo passo per tutte le app del calendario. Nessuna va inviata senza ([SBU-275](/SBU/issues/SBU-275), [SBU-276](/SBU/issues/SBU-276)).
2. **Habits** aspetta la telefonata con Apple ([SBU-263](/SBU/issues/SBU-263)). **Speed** è ancora REJECTED su ASC.
3. **App Privacy** di Chats e Fuel: la compila Matteo sul web ([SBU-276](/SBU/issues/SBU-276)).
4. **TestFlight sul tuo iPhone** e **CI rossa** (test UI di Clean e Noise sui runner GitHub): non riverificati dal 18/10.

## 6. Gli altri due rami

Sezioni 6, 7, 9 e 10: non riverificate il 22/11, ferme al 18/10.

- **Giochi**: ADR-0015, Squares su main e installato sul tuo iPhone ("per ora funziona bene"). Uno al mese dopo Squares: Tiles, Sudoku, Arrows, Sort, Solitaire, Words.
- **Software**: ADR-0016 e pagine `/software` e `/software/commerce` sul sito. Il repo `commerce-dev` non esiste ancora; nessuna riga di codice. Primo passo: lo spike di compatibilità (catalogo, prodotto, carrello). Non annunciato: nessun nome di piattaforma nel materiale pubblico.

## 7. Marketing

Fatto: sito live con i tre rami, Search Console e Bing, Smart App Banner, `sameAs` e `llms.txt`, pagine alternativa, generatore QR e calcolatore abbonamenti, badge con link campagna, RSS, Instagram @sbu_dev, foto stampa, listing AlternativeTo (in moderazione), open-source-ios-apps: Subscriptions in lista (#2443), Scanner in lista (#2446) (una PR per app). In SbuKit (su main, arrivano con la prossima versione di ogni app): richiesta di recensione dopo la Chiusura, Condividi l'app, `SbuFigureCard`. Piano 12 mesi v3.3 in `marketing/plan.md` (copia pubblica), punteggio 53/85.

Deciso e chiuso: niente newsletter (solo RSS), niente GitHub Sponsors, un Show HN per app.

Aperto: indicizzazione delle pagine nuove (#575), handle su X/TikTok/YouTube/LinkedIn, video di Find e "costa 40 € l'anno, l'ho rifatta gratis", articolo "sei app rifiutate" (bozza IT).

## 8. Cosa serve da te (Matteo)

1. App Privacy "nessun dato" sul web per Chats e Fuel (poi Inventory) ([SBU-276](/SBU/issues/SBU-276)).
2. La prova insieme via cavo di Chats e Fuel, prima dell'invio del 23/11.
3. La telefonata con App Review per Habits, quando Apple la fissa ([SBU-263](/SBU/issues/SBU-263)).
4. Notizie su Speed: su ASC è ancora respinta.
5. L'ok a ogni invio del calendario, uno alla volta.
6. Richiesta entitlement multicast per Remote, quando vuoi riprenderla.

## 9. Cosa NON fare adesso

Il rischio vero è disperdersi: 20 app scritte, tre rami, 274 ticket aperti. Finché Apple e il test insieme sono il collo di bottiglia, ogni app nuova allunga la coda senza far uscire niente.

- Nessuna app nuova (Cycle e le pianificate restano ferme) finché la coda "pronte su ASC" non si svuota.
- Software resta allo spike, niente lancio prima di una demo che gira.
- Un fronte al giorno: test insieme, poi invio, poi lancio.

## 10. Pulizia in sospeso

- ~30 branch `worktree-agent-*` locali e i branch `app/*` già fusi: si possono cancellare.
- `Apps/SbuDuo` è un residuo non tracciato (Duo vive sul branch `duo`).
- La tabella stati e il calendario di `docs/factory.md` vanno allineati a questo file o tolti.
