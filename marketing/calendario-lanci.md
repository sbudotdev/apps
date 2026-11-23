# Calendario dei lanci, 23/11 – 15/12/2026

Proposta del 22/11, da approvare. Niente di questo è pubblicato: ogni post, Show HN, PR e invio ad AlternativeTo lo fa Matteo dopo l'ok. Testi in `marketing/<app>/lancio.md`.

## Regole del calendario

- Al massimo uno Show HN a settimana (lunedì-domenica), compreso quello della collezione.
- Mai uno Show HN nel giorno di un invio ad Apple. Gli invii sono quelli di [SBU-324](/SBU/issues/SBU-324): Chats 23/11, Fuel 30/11, Squares 7/12, Prompter 14/12, Inventory 21/12. Aggiornamento del 22/11 alle 23:00 (Matteo in [SBU-309](/SBU/issues/SBU-309)): il 30/11 va a Prompter se [SBU-333](/SBU/issues/SBU-333) è approvato dal QA entro il 29/11, altrimenti a Fuel e Prompter va il 7/12; lo decide il Lead il 30/11. Per gli Show HN conta solo che ogni lunedì c'è un invio, quale app sia non cambia la tabella. Qui si assume che ogni invio cada il **lunedì** della sua settimana (Chats il 23/11 come in stato.md §8). Se un invio si sposta su un giorno di Show HN, lo Show HN slitta al giorno dopo, mai oltre il giovedì.
- Show HN martedì, mercoledì o giovedì, tra le 15 e le 17 ora italiana (mattina negli Stati Uniti). Niente giovedì 26/11 (Thanksgiving, HN vuoto) e niente venerdì 27/11.
- Reddit da uno a tre giorni dopo lo Show HN della stessa app, mai lo stesso giorno.
- Una sola PR a `open-source-ios-apps` aperta alla volta: la successiva dopo il merge. L'ordine è lo stesso degli Show HN.
- Post Instagram e Bluesky: non contano come lancio, possono uscire qualsiasi giorno. Clean, Moon e Noise escono sui social nella prima settimana, perché sono già sullo Store; Level dopo la 1.2 (vedi sotto).
- Ogni pezzo pubblicato va in `marketing/log.md` lo stesso giorno.

## Settimana 1 · 23–29 novembre

| Giorno | Cosa | Testo |
|---|---|---|
| Lun 23/11 | Invio di Chats ad Apple: **niente Show HN** | — |
| Lun 23/11 | Post Clean su Instagram e Bluesky | `clean/lancio.md` |
| Lun 23/11 | Voce Clean su AlternativeTo. La PR `Add Sbu Clean` a open-source-ios-apps solo dopo che `app/clean-1.1` è in main (il codice della 1.1 in vendita è lì) | `clean/lancio.md` |
| Mar 24/11 | **Show HN: Sbu Clean**, 15-17. Il link al codice punta al branch `app/clean-1.1` e il testo lo dice; se Matteo lo fonde in main prima, si torna a `tree/main` | `clean/lancio.md` |
| Mar 24/11, sera | Post Moon su Instagram e Bluesky: è luna piena, ora letta in Sbu Moon il giorno prima | `moon/lancio.md` |
| Mer 25/11 | Reddit r/iosapps: post di Clean | `clean/lancio.md` |
| Mer 25/11, 9:00 | Sbu Commerce v0.1.0: post LinkedIn di Matteo (IT, poi EN) e post Bluesky/X. Non è uno Show HN; se l'ok arriva dopo, martedì 1/12 alle 9:00 | `commerce/lancio.md` |
| Gio 26/11, sera | Post Noise su Instagram e Bluesky | `noise/lancio.md` |

Aggiornamenti (Moon 1.1, Level 1.2, Noise 1.1): Moon 1.1 e Noise 1.1 sono in vendita dal 22/11, prima dei loro post di lancio. Quindi il 24/11 e il 26/11 escono i post di lancio con l'immagine nuova e i post degli aggiornamenti di Moon e Noise si saltano. Level 1.2 è ancora in revisione: il suo post esce il giorno dopo `READY_FOR_SALE`, mai nello stesso giorno di un altro post della stessa app. Se Moon 1.1 o Noise 1.1 escono prima del post di lancio di questa settimana, si pubblica solo il post di lancio, con l'immagine nuova, e il post dell'aggiornamento si salta. Testi nella sezione «Aggiornamento» di ogni `lancio.md`.

Chats: post Instagram e Bluesky il giorno dopo `READY_FOR_SALE`. Testi in `chats/lancio.md`.

## Settimana 2 · 30 novembre – 6 dicembre

| Giorno | Cosa | Testo |
|---|---|---|
| Lun 30/11 | Invio di Prompter o Fuel ad Apple: **niente Show HN** | — |
| Lun 30/11 | Voce Moon su AlternativeTo; PR `Add Sbu Moon` se quella di Clean è fusa | `moon/lancio.md` |
| Mer 2/12 | **Show HN: Sbu Moon**, 15-17 | `moon/lancio.md` |
| Gio 3/12 | Reddit r/SideProject: post di Moon | `moon/lancio.md` |

## Settimana 3 · 7–13 dicembre

| Giorno | Cosa | Testo |
|---|---|---|
| Lun 7/12 | Invio ad Apple (Squares, o Prompter se il 30/11 è andato a Fuel): **niente Show HN** | — |
| Lun 7/12 | Voce Noise su AlternativeTo; PR `Add Sbu Noise` se quella di Moon è fusa | `noise/lancio.md` |
| Mer 9/12 | **Show HN: Sbu Noise**, 15-17 (non martedì 8/12: è l'Immacolata) | `noise/lancio.md` |
| Gio 10–Ven 11/12 | Reddit r/sleep, solo risposte a thread pertinenti | `noise/lancio.md` |
| Gio 10/12 | **Controllo per lo Show HN della collezione**: quante app sono in vendita? (vedi sotto) | `plan.md` §9 #25 |

## Settimana 4 · 14–15 dicembre

| Giorno | Cosa | Testo |
|---|---|---|
| Lun 14/12 | Invio ad Apple (l'app che segue in coda, la sceglie il Lead): **niente Show HN** | — |
| Mar 15/12 | **Show HN della collezione**, 15-16, solo se ≥ 8 app in vendita | da scrivere (`plan.md` §9 #24) |
| Mer 16/12 o settimana dopo | Product Hunt della collezione (non è uno Show HN, la regola settimanale non vale) | da scrivere |

## Level: perché è fuori dalle quattro settimane

Le settimane libere per uno Show HN sono quattro e la quarta è della collezione. Le app sono quattro. Level va per ultima perché il binario in vendita è ancora la 1.0: il mirino con la fotocamera, che è l'aggancio per HN, arriva con la 1.2, in revisione dal 22/11.

- Se la collezione esce il 15/12: **Show HN di Level martedì 5/1/2027** (21/12–3/1 niente lanci, `plan.md` §9), con la 1.2 in vendita.
- Se la collezione slitta al 12/1 (meno di 8 app il 10/12): la settimana del 14/12 si libera e lo Show HN di Level va **martedì 15/12**, se la 1.2 è in vendita. Altrimenti resta il 5/1.
- Il post social di Level esce dopo l'approvazione della 1.2: il listing della 1.1 promette già le funzioni nuove, e chi arriva dal post non le troverebbe. Il primo sabato dopo l'approvazione.

## La collezione: si arriva a 8 app il 15/12?

Oggi (22/11) sono in vendita 7 app: Subscriptions, Scanner, Find, Moon, Clean, Level, Noise. Con Chats (invio 23/11) e Fuel (invio 30/11) approvate entro il 14/12 si arriva a 9; ne basta una delle due per arrivare a 8. Squares (invio 7/12) è un gioco: conta se approvata in tempo, ma non ci si conta.

Il rischio è a monte dell'invio: Chats e Fuel non partono senza la prova insieme via cavo e l'App Privacy (`docs/stato.md` §5). Se il 10/12 le app in vendita sono 7, lo Show HN della collezione va al 12/1 come da piano, e il 15/12 passa a Level.

Habits e Speed non entrano nel conto: sono ancora respinte.

## Fuori calendario, da tenere presente

- **Find**: lo Show HN di Find non è registrato in `marketing/log.md` (vuoto al 22/11) e la PR a open-source-ios-apps per Find non risulta aperta. Se non è stato fatto, va nella settimana del 4/1 al posto di Level, oppure in quella dell'11/1: mai due Show HN nella stessa settimana.
- **Chats**: Show HN a gennaio, nella prima settimana libera dopo Level e Find. Reddit r/iosapps non prima di un mese dopo il post di Clean.
- **Inventory**: l'invio del 21/12 cade nella pausa di Natale; il lancio va a gennaio, dopo Chats.
- **Sbu Seasons**: il Reel e il post LinkedIn escono quando arriva il video di Matteo ([SBU-157](/SBU/issues/SBU-157)), alle 18:30. Non è uno Show HN.
- **Natale** (21/12–3/1): niente lanci, solo il ritmo fisso e l'articolo di fine anno (`plan.md` §9).
- **Luna piena del 24/12**: secondo post Moon possibile, la sera della vigilia, se il primo ha funzionato.
