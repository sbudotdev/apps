# Sbu Social: l'Originale diventa BePresent, tre tab, niente rete

Sostituisce ADR-0017 e ritira ADR-0018. Il numero salta 0019 e 0020, già presi dai rami di Sbu ZTL.

**L'Originale cambia.** Sbu Social non rifà più SocialLite ma BePresent (ADR-0004: un solo **Originale** per app). Il browser filtrato, le **Piattaforme**, gli **Account**, le **Regole**, la **Modalità post**, il **Limite di tempo** e la tab Sonno escono dall'app. Restano bundle id, app group ed estensioni Screen Time, perché l'entitlement Family Controls è legato a quelli. La **Cosa sola**: tiene le app chiuse quando hai deciso tu.

**Cosa fa.** Tre leve, tutte sul telefono:

- **Intenzione**: un'app che apri al massimo N volte al giorno, M minuti per volta, nei giorni scelti. In quei giorni l'app è coperta dallo **Schermo**, che conta le **Aperture** di oggi e ha il bottone per aprirla; finiti i minuti lo Schermo torna da solo. Oltre N l'app si apre ancora, ma il giorno non conta per la **Serie**.
- **Blocca ora** e **Sessioni**: tutte le app chiuse tranne le **App consentite** (al massimo 50, limite di Screen Time), subito per i minuti scelti oppure a orari fissi nei giorni scelti. Durante un blocco lo Schermo ha solo il bottone per chiudere.
- **Obiettivo giornaliero**: i minuti di schermo che ti dai per oggi, con una notifica quando li raggiungi.

Sopra le leve c'è il conto dei progressi, anche lui solo sul telefono: la **Serie** dei giorni tenuti, i punti, la **Missione del giorno** (tre compiti).

**Fuori, e perché.** Account e nome utente, abbonamento, classifica e leghe, gruppi, SMS a un'altra persona, link di tracciamento, quiz iniziale: BePresent li ha, ma chiedono un server, un acquisto o dati che lasciano il telefono, e le regole di prodotto li vietano senza eccezioni possibili. Niente coriandoli, emoji o schermate colorate: la grafica è Quaderno come nelle altre app, e il rischio di copia (linea guida 4.1) resta coperto da grafica, icona, nome, testi e screenshot nostri.

**Niente rete.** Senza il browser l'app non fa più chiamate: l'eccezione di ADR-0018 non serve e nessuno la eredita. I dati di Screen Time non escono dall'app nemmeno verso Sbu: il sistema li mostra solo dentro la sua estensione, e l'app sa soltanto se l'Obiettivo giornaliero è stato raggiunto.

**Tre tab.** `TabView` nativa dentro `SbuTabShell`, come ADR-0012: **Home** (`house`), **Sessioni** (`calendar`) e **Impostazioni** (`gearshape`), l'ultima, aggiunta dalla shell. L'app si apre su Home, la **Schermata strumento**. Ogni tab ha al massimo una **Cifra**: Home il tempo in blocco oggi, Sessioni quante Sessioni sono accese; Impostazioni nessuna. Il **Punto fermo** è pieno dove qualcosa è in corso: in Home e in Sessioni mentre un blocco è in corso; altrimenti è in attesa. Niente tab Tempo di schermo con i minuti di oggi: il sistema li mostra solo dentro un'estensione DeviceActivityReport, che vorrebbe una nuova richiesta di entitlement; se servirà, sarà un nuovo ADR.

**Primo avvio a passaggi.** Deroga alla regola "niente caroselli al primo avvio": l'app senza Screen Time, un'Intenzione e le App consentite non fa nulla, quindi il primo avvio è una configurazione, un passaggio per cosa da impostare (accesso a Tempo di utilizzo, Obiettivo giornaliero, prima Intenzione, prima Sessione, App consentite, widget). Ogni passaggio fa una cosa, si può saltare, e chiede il suo permesso solo quando lo usa: mai in anticipo. Nessun passaggio serve a convincere.

Motivo: la decisione del 5/11/2026 di rifare BePresent, la prima app della nicchia "Schermo" nelle classifiche del 15/10, partendo da Sbu Social invece che da un'app nuova. Due blocker dello stesso sviluppatore sarebbero un doppione (4.3), e ogni estensione nuova vuole la sua richiesta di entitlement, con attese di settimane. Alternative scartate: una seconda app accanto a Sbu Social; tenere il browser e aggiungere le Intenzioni, che dà un'app con due cose; un server per classifica e SMS, che rompe le promesse. Nessun'altra app può usare le deroghe di questo ADR senza un nuovo ADR.
