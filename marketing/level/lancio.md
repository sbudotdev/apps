# Lancio di Sbu Level: kit

Stato il 22/11/2026: **1.1 (3) in vendita**, approvata da Apple il 22/11 (app 6822656774). Attenzione: quel binario è ancora la 1.0. Il mirino con la fotocamera, le unità %, x:12 e 1V:H, "Azzera qui", la voce che legge l'angolo e il tasto volume arrivano con la **1.2 (7), in revisione dal 22/11**. Finché la 1.2 non è in vendita, i testi parlano solo delle funzioni sotto. Pagina: sbu.dev/apps/level. Il sito indica l'app che sostituisce ("Clinometer + bubble level", 1,99 €) sulla pagina dell'app; non c'è una pagina alternativa dedicata. Date nel calendario: `marketing/calendario-lanci.md`.

Tutto qui è bozza: Matteo approva e pubblica. Modello: `marketing/find/`.

Funzioni in vendita oggi (descrizione dello Store della 1.0): appoggi l'iPhone e la bolla dice se è in piano; in piedi su un bordo diventa un clinometro da 0° a 90° con quadrante e lancetta, su tutti e quattro i bordi, al decimo di grado; scelta automatica tra bolla e clinometro; blocco della lettura; calibrazione in due passaggi per ogni lato, anche su una superficie non in piano; schermo sempre acceso mentre misuri; un colpo di vibrazione quando sei esattamente in piano.

Onestà sul prodotto: la precisione dipende dai sensori dell'iPhone e dalla calibrazione. Mai "precisione da laser" o "certificata": si dice "al decimo di grado, dopo la calibrazione".

Quando la 1.2 è in vendita: aggiungere al post e allo Show HN il mirino ("guarda un tetto o un albero dalla fotocamera e leggi l'angolo"), che è l'aggancio più forte. Per questo lo Show HN di Level va dopo l'approvazione della 1.2 (vedi calendario).

## Instagram @sbudevapp

**Quando:** dopo l'approvazione della 1.2. La descrizione dello Store della 1.1 in vendita promette già il mirino e le unità nuove, ma il binario è la 1.0: chi arriva dal post troverebbe nel listing funzioni che non ci sono. Con la 1.2 in vendita, aggiungere al post il mirino.

Immagine: primo screenshot dello Store. Testo sull'immagine: "È dritto? Chiedilo all'iPhone."

IT:
> Appoggi l'iPhone sulla mensola e la bolla ti dice se è dritta. Lo metti in piedi su un bordo e diventa un clinometro: leggi l'angolo al decimo di grado.
>
> Sbu Level sceglie da solo tra bolla e clinometro, tiene lo schermo acceso mentre misuri e vibra quando sei in piano. Se il tavolo su cui lo calibri non è dritto, la calibrazione in due passaggi lo corregge.
>
> Niente abbonamento, niente account, niente pubblicità, niente tracking.
>
> Link in bio: sbu.dev/apps/level

EN:
> Lay your iPhone on the shelf and the bubble tells you if it's level. Stand it on an edge and it becomes a clinometer: read the angle to a tenth of a degree.
>
> Sbu Level picks bubble or clinometer on its own, keeps the screen on while you measure and buzzes when you're level. If the table you calibrate on isn't straight, the two-step calibration corrects for it.
>
> No subscription, no account, no ads, no tracking.
>
> Link in bio: sbu.dev/en/apps/level

## Bluesky @sbu.dev

IT (≤300):
> Sbu Level è sull'App Store. Livella a bolla quando è appoggiato, clinometro da 0° a 90° quando è in piedi, al decimo di grado. Calibrazione in due passaggi, anche su un tavolo storto. Gratis, senza account.
> sbu.dev/apps/level

EN (≤300):
> Sbu Level is on the App Store. A bubble level when flat, a 0 to 90° clinometer on its edge, to a tenth of a degree. Two-step calibration that works even on a crooked table. Free, no account.
> sbu.dev/en/apps/level

## Reddit: r/HomeImprovement, solo come risposta

Un solo sub. r/HomeImprovement è il posto dove la gente chiede "l'app livella dell'iPhone è affidabile?". Niente post di lancio: si risponde nei thread pertinenti, con il consiglio prima del link, dichiarando che l'app è tua. **Rileggere sidebar e regole il giorno stesso** (il 22/11 non abbiamo potuto scaricarle): se la self-promotion è vietata anche nei commenti, si risponde senza link oppure si salta.

Thread da cercare: "is the iPhone level app accurate", "phone level vs real level", "measure roof pitch with phone".

Risposta modello (EN):
> For hanging shelves or pictures a phone level is fine. The catch is calibration: the phone's sensor has a small offset, so calibrate it on a surface, then flip it 180° on the same spot and calibrate again. That cancels the offset even if the surface itself isn't level. For a long run (a countertop, a deck) use a real 4 ft level; the phone is only as long as the phone.
>
> I made a free level/clinometer that does that two-step calibration on every edge (disclosure: it's mine, no IAP, no ads): sbu.dev/en/apps/level

Il flusso "misura, gira di 180° sullo stesso punto, misura" è quello dell'app (`Apps/SbuLevel/SbuLevel/Level/CalibrationSession.swift`), controllato il 22/11.

## Show HN

Dopo l'approvazione della 1.2, nella settimana indicata in `calendario-lanci.md`, tra le 15 e le 17 ora italiana. Mai nella settimana di un altro Show HN, mai nel giorno di un invio ad Apple. Il testo sotto è scritto per la 1.2; se esce prima, togliere il paragrafo del mirino e le unità nuove.

Titolo (≤80): `Show HN: A free iPhone level and clinometer with a camera sight` (63)

Alternativa (se la 1.2 non è ancora in vendita): `Show HN: Bubble level and clinometer for iPhone, two-step calibration, free` (75)

Primo commento:
> Hi HN, I'm Matteo, a computer security student in Milan.
>
> The well-known clinometer and bubble level apps on the App Store are cheap, around €1.99, or free with ads. It's a small job done well by a few, so I wanted one that's free, has no ads and shows its code.
>
> Sbu Level is a bubble level when the phone lies flat and a 0-90° clinometer when it stands on any of its four edges, to a tenth of a degree. Calibration is two-step per side: measure, rotate 180° on the same spot, measure again. That cancels the sensor offset even on a surface that isn't level. You can lock the reading, the screen stays on, and it buzzes when you're exactly level.
>
> [Solo con la 1.2 in vendita] The sight uses the camera to read the angle of your line of sight to a distant point, a roof or a treetop, with horizon and crosshair; no photo is saved. Units in degrees, percent, x:12 (roof pitch) and 1V:H. "Zero here" measures relative to a surface that isn't level, and a voice reads the angle when it settles, so you can measure without looking.
>
> Method: specs come only from public App Store data (listings, screenshots, reviews). Nothing decompiled. Built with Claude, every line reviewed by me; Swift 6, SwiftUI, Core Motion, iOS 17+.
>
> Privacy: no account, no analytics, no ads, no server. The camera picture stays on screen.
>
> It's one of [N, ricontare il giorno stesso: 7 al 22/11] free iPhone apps I have on the store at sbu.dev, each doing one thing with no subscription.
>
> Repo: https://github.com/sbudotdev/apps/tree/main/Apps/SbuLevel
> Page: https://sbu.dev/en/apps/level

Risposte pronte:

1. **"How accurate is it?"**
   > As accurate as the phone's accelerometer after calibration, which in practice is a few tenths of a degree. It shows tenths because that's what the sensor resolves, not because I promise them on every phone.

2. **"iOS already has a level in the Measure app."**
   > It does, and for a quick check it's enough. Sbu Level adds the clinometer on all four edges with a dial, per-side calibration, a locked reading and, with 1.2, the camera sight and roof-pitch units.

3. **"Why does a level need the camera?"**
   > Only for the sight, to measure the angle to something you can't touch. The picture is never saved or sent. Without permission everything else works.

4. **"Free means a paywall later."**
   > No IAP, no ads, no SDKs, no account. There's nothing to monetise. The code is public.

Core Motion e la calibrazione con la rotazione di 180° sono controllati nel codice il 22/11 (`MotionSource.swift`, `CalibrationSession.swift`). Prima di pubblicare: rileggere il prezzo di Clinometer su apps.apple.com.

## PR a open-source-ios-apps

Una PR per app, una aperta alla volta (si apre dopo il merge della precedente). Titolo: `Add Sbu Level`.

```json
{
  "title": "Sbu Level",
  "description": "Bubble level and clinometer on all four edges, two-step calibration, no ads or tracking",
  "category-ids": ["misc"],
  "tags": ["swift", "swiftui"],
  "screenshots": [
    "https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/b7/ae/a7/b7aea7a9-b2ac-39b9-d757-0ac190edd24d/iPhone_17_Pro_Max-01-main_framed.png/320x480bb.jpg"
  ],
  "source": "https://github.com/sbudotdev/apps/tree/main/Apps/SbuLevel",
  "itunes": "https://apps.apple.com/app/id6822656774",
  "license": "mit",
  "date_added": "[data del giorno]",
  "suggested_by": "@mgiuditta"
}
```

Corpo della PR:
> Sbu Level: bubble level and clinometer, free and open source SwiftUI (MIT). One entry in contents.json.

## AlternativeTo

Voce nuova "Sbu Level", alternativa a **Clinometer + bubble level** (come indica la pagina sbu.dev/apps/level). Categoria: Utilities. Licenza: Free, Open Source. Piattaforma: iPhone. Tag: bubble-level, clinometer, inclinometer, spirit-level, no-ads.

Descrizione breve (≤140):
> Free bubble level and clinometer for iPhone. 0 to 90° on all four edges, two-step calibration, no ads, no account.

Descrizione lunga:
> Sbu Level is a bubble level when your iPhone lies flat and a clinometer from 0° to 90° when it stands on any of its four edges, read to a tenth of a degree on a dial with a needle. It picks the mode on its own, locks a reading, keeps the screen on while you measure and gives a haptic tap when you are exactly level. Two-step calibration per side works even on a surface that isn't level.
>
> There is no in-app purchase, no account, no ads and no analytics, and the source code is public under MIT.

(Quando la 1.2 è in vendita: aggiungere il mirino con la fotocamera e le unità %, x:12, 1V:H.)

## Aggiornamento 1.2 (7): il post di Level

Stato: `IN_REVIEW` nella fotografia ASC di [SBU-324](/SBU/issues/SBU-324) del 22/11 alle 22:50. Il 22/11 alle 23:07 il lookup pubblico dello Store dà ancora la **1.1** (binario 1.0). Lo stato ASC lo scrive [SBU-324](/SBU/issues/SBU-324). **Si pubblica solo quando la 1.2 è `READY_FOR_SALE`** e il lookup `https://itunes.apple.com/lookup?id=6822656774&country=it` risponde `"version":"1.2"`. Questi post **sostituiscono** quelli di Instagram e Bluesky sopra: con la 1.2 il listing e l'app dicono le stesse cose. Il primo sabato dopo l'uscita (calendario).

Novità (testo su ASC, copiato in [SBU-324](/SBU/issues/SBU-324); il `release_notes.txt` su main è diverso e non va usato): icona nuova, con l'alternativa Inversa nelle impostazioni, e schermate rifatte sul quaderno; mirino con la fotocamera per misurare l'angolo di un punto lontano, un tetto o un albero; unità in gradi, %, x:12 e 1V:H; Azzera qui per l'angolo relativo; blocco a lettura stabile; voce che legge la cifra; suono alla misura; tasto volume nel mirino; quadrante che ruota; schermo intero con un tocco; pagina Come si usa.

Immagine: `/Users/matteo/dev/sbudotdev/apps-sbu-267/Apps/SbuLevel/fastlane/screenshots/it/iPhone 17 Pro Max-01-main_framed.png` (EN: stessa cartella con `en-US`). Generata il 22/11, worktree di [SBU-267](/SBU/issues/SBU-267), fuori dal repo. Nessuno dei cinque screenshot mostra il mirino: se Matteo vuole un'immagine del mirino, serve uno screenshot dal telefono (la fotocamera non va nel simulatore).

Instagram IT:
> Quanto è inclinato quel tetto? Apri il mirino di Sbu Level, inquadra la falda e leggi l'angolo. Funziona anche con un albero o un palo lontano.
>
> Con la 1.2 scegli l'unità che ti serve: gradi, percentuale, x:12 o 1V:H. "Azzera qui" misura un angolo rispetto a un altro. Quando la lettura è stabile si blocca, e se vuoi una voce ti legge la cifra.
>
> C'è anche un'icona nuova: se la preferisci chiara su fondo scuro, nelle impostazioni c'è l'Inversa.
>
> Appoggiato resta una livella a bolla, in piedi su un bordo un clinometro al decimo di grado, dopo la calibrazione.
>
> Niente abbonamento, niente account, niente pubblicità, niente tracking.
>
> Link in bio: sbu.dev/apps/level

Instagram EN:
> How steep is that roof? Open the sight in Sbu Level, aim at the slope and read the angle. It works on a tree or a distant pole too.
>
> With 1.2 you pick the unit you need: degrees, percent, x:12 or 1V:H. "Zero here" measures one angle against another. When the reading is steady it locks, and a voice can read the figure out.
>
> There's a new icon too: if you'd rather have it light on dark, pick Inversa in Settings.
>
> Laid flat it's still a bubble level, on its edge a clinometer to a tenth of a degree, after calibration.
>
> No subscription, no account, no ads, no tracking.
>
> Link in bio: sbu.dev/en/apps/level

Bluesky IT (≤300):
> Sbu Level 1.2 è sull'App Store: icona nuova, un mirino con la fotocamera per leggere l'angolo di un tetto o di un albero, unità in gradi, %, x:12 e 1V:H, una voce che legge la cifra. Gratis, senza account.
> sbu.dev/apps/level

Bluesky EN (≤300):
> Sbu Level 1.2 is on the App Store: a new icon, a camera sight to read the angle of a roof or a tree, units in degrees, %, x:12 and 1V:H, a voice that reads the figure. Free, no account.
> sbu.dev/en/apps/level

Precisione: la regola sopra vale anche per il mirino. Mai "preciso come un laser": l'angolo dipende dai sensori e dalla calibrazione.
