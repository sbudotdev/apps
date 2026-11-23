# Stato di sbu.dev — 23 novembre 2026

Fotografia del 23/11 alle 23:00. Gli stati App Store Connect sono letti dall'API (chiave `ASC_*`, sola lettura) il 23/11 alle 22:50; il resto viene da GitHub e dai ticket indicati riga per riga. Sostituisce la versione del 22/11.

## In una frase

Sullo Store ci sono 7 app, tutte alla versione nuova (Level 1.2 approvata il 23/11). Chats e Habits sono in revisione. Prompter e Squares sono su TestFlight. Resta fuori solo Speed. La CI di questo repo è spenta dal 23/11 sera, su richiesta di Matteo.

## 1. Sullo Store oggi

| App | Versione in vendita (build) | Fonte |
|---|---|---|
| Sbu Subscriptions | **2.1.0** (7) | API ASC 23/11 |
| Sbu Scanner | **2.0.1** (4) | API ASC 23/11 |
| Sbu Find | **1.0** (3) | API ASC 23/11 |
| Sbu Clean | **1.1** (7) | API ASC 23/11 |
| Sbu Moon | **1.1** (4), uscita il 22/11 | API ASC 23/11, [SBU-324](/SBU/issues/SBU-324) |
| Sbu Noise | **1.1** (5), uscita il 22/11 | API ASC 23/11, [SBU-324](/SBU/issues/SBU-324) |
| Sbu Level | **1.2** (7), approvata il 23/11 | API ASC 23/11 |

Fuori dallo Store: **Sbu Seasons** (Mac) **2.3.0** (13), .dmg notarizzato, release `v2.3.0` in [sbudotdev/seasons](https://github.com/sbudotdev/seasons); **Sbu Prompter** (Mac) **1.0.1**, release `prompter-1.0.1` di questo repo.

## 2. In revisione

| App | Versione (build) | Inviata | Nota |
|---|---|---|---|
| Sbu Chats | 1.0 (5) | 23/11, 11:53 | prima versione; moduli di conformità (Cina) compilati su tutte le app ([SBU-378](/SBU/issues/SBU-378)) |
| Sbu Habits | 1.1 (7) | 23/11, 19:07 | reinvio dopo il rifiuto del 23/11 (guideline 4: icona Watch nera, non circolare). Icona Watch ora chiara nel cerchio ([apps#94](https://github.com/sbudotdev/apps/pull/94)); la spiegazione è nelle note per la review, perché con l'invio in attesa il Resolution Center non accetta risposte. La build 8 è valida ma non agganciata: `main` è già a 8, il prossimo caricamento parte da 9 ([SBU-410](/SBU/issues/SBU-410)) |

## 3. Tutte le altre app, una riga ciascuna

Ogni app è su `main`, tranne ZTL. "Prossimo passo" è l'unica cosa che sblocca l'app.

### Ancora respinta

| App | ASC (API 23/11) | Prossimo passo | Fonte |
|---|---|---|---|
| Speed | 1.1 (2) agganciata, build 6 caricata; rifiuto 4.3 del 14/10 non risolto | telefonata con Apple (Matteo), poi piano B: build nuova con la nota "could a human look at this app?" | [SBU-263](/SBU/issues/SBU-263) |

### Su TestFlight o pronte su ASC, non inviate

| App | ASC (API 23/11) | Manca | Fonte |
|---|---|---|---|
| Prompter (Mac + iPhone) | 1.0 macOS e iOS PREPARE_FOR_SUBMISSION. Build **1.0 (3)** Mac e iPhone da `main` del 23/11 su TestFlight (gruppo interno). Alla versione sono ancora agganciate le build 2 (Mac) e 1 (iPhone) | agganciare la build 3, screenshot, invio nello slot | [SBU-333](/SBU/issues/SBU-333) |
| Squares (primo gioco) | record creato il 23/11 (Apple ID 6838484975, SKU `dev.sbu.squares`), build **1.0 (1)** su TestFlight (gruppo interno) | prova su TestFlight, screenshot e metadati (`fastlane release`), invio il 7/12 | [SBU-275](/SBU/issues/SBU-275) |
| Fuel | 1.0 (5) PREPARE_FOR_SUBMISSION, moduli e App Privacy fatti | invio nello slot | [SBU-282](/SBU/issues/SBU-282) |
| Inventory | 1.0 (4) PREPARE_FOR_SUBMISSION | invio nello slot | [SBU-305](/SBU/issues/SBU-305) |
| ZTL | 1.0 PREPARE_FOR_SUBMISSION, nessuna build agganciata (build 2 del 01/11) | vive sul branch `app/ztl`, fuori calendario | API ASC 23/11 |

### Scritte, mai su ASC

| App | Manca |
|---|---|
| Shrink, Grid, Tidy, Libretto | test sul device, record ASC, TestFlight |
| Meds | test del task in background sul device, record ASC, TestFlight |
| Remote | prova su una TV vera, richiesta entitlement multicast (Matteo, `docs/remote-multicast-entitlement.md`), record ASC |

### Pianificate, non iniziate

Cycle, Cast, Image, Gif, Tags, Knit, Chores, Reader, Exposure.

## 4. Calendario degli invii

Un'app nuova a settimana ([SBU-275](/SBU/issues/SBU-275)). **Ogni invio va approvato a parte.**

| Settimana | App |
|---|---|
| 23/11 | Sbu Chats (inviata) e Sbu Habits (reinvio dopo rifiuto) |
| 30/11 | Sbu Prompter se pronto, altrimenti Sbu Fuel |
| 7/12 | Sbu Squares (primo gioco) |
| 14/12 | quella tra Prompter e Fuel rimasta indietro |
| 21/12 | Sbu Inventory |
| poi | Shrink, Grid, Tidy, Libretto, Meds |

## 5. Repo, CI e strumenti

- **CI spenta**: il workflow `CI` è disattivato dal 23/11 sera (`gh workflow disable CI`), su richiesta di Matteo. Per riaccenderlo: `gh workflow enable CI -R sbudotdev/apps`. Finché è spenta, prima di ogni merge si lanciano i test in locale.
- **Ultimo stato della CI su `main`**: rossa su SbuHabits per i timeout dell'audit di accessibilità («Audit failed to complete in time»). [apps#96](https://github.com/sbudotdev/apps/pull/96) aggiunge il riprova per Habits, Moon e Speed (come #92 per Noise), unita ma mai girata su `main`. Restano due test di Moon che non sono timeout: `testToolScreenShowsTheFigureAndPassesTheAccessibilityAudit` e `testPhaseAlertsInSettings` ([SBU-279](/SBU/issues/SBU-279)).
- **Simulatori di questo Mac**: reinstallati da zero il 23/11 (iOS 27.0, iOS 27.1, watchOS 27.0). iOS 27.1 supporta solo «iPhone Duo»: «Incompatible device» su iPhone 17 con 27.1 è normale. I test (`run_tests(devices: ["iPhone 17"])`) girano su iOS 27.0.
- **Numeri di build**: `CURRENT_PROJECT_VERSION` in `project.yml` è l'ultima build caricata per Chats, Fuel, Habits, Inventory, Level, Moon, Noise, Speed, Squares. Prompter (`fastlane upload`, [apps#88](https://github.com/sbudotdev/apps/pull/88)) e le app su `fastlane beta` (Clean, Find, Scanner, Subscriptions) prendono il numero da TestFlight e il valore locale non conta: per Prompter la prossima build è la 4.
- **PR aperte**: nessuna. Il 23/11 sera sono state unite [apps#88](https://github.com/sbudotdev/apps/pull/88) (Prompter verso l'App Store: `fastlane upload`, screenshot, note per la review; 88 test Mac e 26 iOS verdi in locale) e [apps#93](https://github.com/sbudotdev/apps/pull/93) (piano di crescita Instagram, QA in [SBU-406](/SBU/issues/SBU-406); il reel di Seasons che contiene è annullato).

## 6. Gli altri due rami

- **Giochi**: ADR-0015. Squares su TestFlight, invio il 7/12. Uno al mese dopo Squares: Tiles, Sudoku, Arrows, Sort, Solitaire, Words.
- **Software**: ADR-0016. **Sbu Commerce v0.1.0** pubblicata il 23/11 in [sbudotdev/commerce](https://github.com/sbudotdev/commerce) (MIT, CI verde): catalogo, ricerca, carrello anonimo e storefront di riferimento con `docker compose`. Il lavoro continua nella privata `commerce-dev` ([SBU-358](/SBU/issues/SBU-358)). Sul sito `/software/commerce` dice ancora «In costruzione»: la correzione è [site#16](https://github.com/sbudotdev/site/pull/16).

## 7. Marketing

- **Instagram @sbu_dev**: foto profilo, copertine, 3 post di apertura e bio in inglese ([SBU-386](/SBU/issues/SBU-386)). Le 5 Storie in evidenza le pubblica Matteo (istruzioni in SBU-386). Piano di crescita in `marketing/`.
- **Lancio di Sbu Commerce**: post per LinkedIn, Bluesky e X approvati da Matteo, escono **mercoledì 25/11 alle 9:00** e li pubblica lui ([SBU-363](/SBU/issues/SBU-363)). Dopo l'uscita vanno registrati in `marketing/log.md`.
- **Reel di Sbu Seasons**: annullato il 23/11, manca la registrazione di Matteo ([SBU-404](/SBU/issues/SBU-404)).
- Piano 12 mesi in `marketing/plan.md`. Deciso e chiuso: niente newsletter (solo RSS), niente GitHub Sponsors, un Show HN per app. Metà dicembre: lancio della collezione (Show HN + Product Hunt).

## 8. Cosa serve da te (Matteo)

1. Il 25/11 alle 9:00: i post di lancio di Sbu Commerce.
2. Provare Prompter e Squares da TestFlight (l'invito è sulla tua email).
3. La telefonata con App Review per Speed (e per Habits, se torna indietro) ([SBU-263](/SBU/issues/SBU-263)).
4. L'ok a ogni invio del calendario, uno alla volta.
5. Il token nuovo `ntfy_token` nei Secrets di Paperclip: finché manca, gli agenti non mandano notifiche (401).
6. Le 5 Storie in evidenza su Instagram.
7. Richiesta entitlement multicast per Remote, quando vuoi riprenderla.

## 9. Cosa NON fare adesso

- Nessuna app nuova (Cycle e le pianificate restano ferme) finché la coda "pronte su ASC" non si svuota.
- Un invio a settimana: la regola tiene lontano il 4.3.
- Niente merge senza test locali verdi finché la CI è spenta.

## 10. Pulizia in sospeso

- ~30 branch `worktree-agent-*` locali e i branch `app/*` già fusi: si possono cancellare.
- `Apps/SbuDuo` è un residuo non tracciato (Duo vive sul branch `duo`).
- La tabella stati e il calendario di `docs/factory.md` vanno allineati a questo file o tolti.
