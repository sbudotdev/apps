# Lancio di Sbu Clean: kit

Stato il 22/11/2026: **1.1 (7) in vendita**, approvata da Apple il 22/11 (app 6822655310). Pagina: sbu.dev/apps/clean. Pagina alternativa online: sbu.dev/alternatives/cleanup (IT) e sbu.dev/en/alternatives/cleanup (EN). Date nel calendario: `marketing/calendario-lanci.md`.

Tutto qui è bozza: Matteo approva e pubblica. Materiale già scritto e ancora valido: `hooks.md`, `reddit.md`, `press.md`, `video.md` in questa cartella. Questo file sostituisce `showhn.md` per il primo commento (quello vecchio diceva "no contacts merge" e cita la repo come non ancora pubblica).

Prima di pubblicare qualsiasi testo con un prezzo: riaprire Cleanup su apps.apple.com (IT e US), aggiornare data e cifre qui e in `hooks.md`. I prezzi sotto sono di listino, letti il 15/10 e il 17/10. Sempre "fino a".

Cosa fa la 1.1 in vendita. Fonte: descrizione dello Store, che viene dal branch `app/clean-1.1` (da qui è uscito il binario 7). Il branch è fuso in main dal 22/11 (PR #80, SBU-291).
- scorri a sinistra per il cestino e a destra per tenere: mese per mese, Recenti, Casuale, un album alla volta;
- metti da parte le foto incerte e decidi dopo, oppure tienile sempre;
- doppioni e foto simili trovati con Vision sull'iPhone, la migliore già scelta;
- screenshot e registrazioni dello schermo in griglia; video dal più pesante, con compressione; Live Photo in foto;
- cestino con revisione finale e conferma di iOS; spazio liberato; widget con lo spazio libero;
- Accadde oggi con il calendario;
- video simili;
- foto sfocate o mosse;
- foto salvate dalle chat, in una griglia (nei testi pubblici non si nomina nessuna app di messaggi);
- contatti doppi: stesso numero, email o nome, uniti in uno, con una copia in File prima di unirli.
Non fa: email, "pulizia" di iCloud, ritocchi con l'AI.

**Codice da linkare.** Il codice della 1.1 è in main dal 22/11 (PR #80, SBU-291): i link puntano a `github.com/sbudotdev/apps/tree/main/Apps/SbuClean`.

**Store, da sistemare alla prossima versione (fuori da questo kit).** La descrizione live di Clean e le note per App Review nominano un'app di messaggi in chiaro, contro la regola di `apps/CLAUDE.md`. I metadati in main sono già corretti (PR #79, SBU-288): arrivano sullo Store con la prossima versione di Clean.

## Instagram @sbu_dev

Immagine: primo screenshot dello Store (`iPhone_17_Pro_Max-01-main_framed`). Testo sull'immagine: "Elimina quante foto vuoi. Gratis."

IT:
> Scorri le foto, a sinistra quelle da buttare, a destra quelle da tenere. Poi le elimini. Tutto qui, e non costa niente.
>
> Sbu Clean trova doppioni, foto simili e foto mosse sull'iPhone, mette in fila gli screenshot e ordina i video dal più pesante. Già che c'è, unisce i contatti salvati due volte. Prima di eliminare rivedi il cestino, e iOS chiede conferma una seconda volta.
>
> Molte app di pulizia ti fanno scorrere gratis e poi chiedono un abbonamento, anche settimanale, per il tasto Elimina. Qui il tasto Elimina è gratis.
>
> Niente abbonamento, niente account, niente pubblicità, niente tracking. Le foto restano sull'iPhone.
>
> Link in bio: sbu.dev/apps/clean

EN:
> Swipe left on the photos you don't want, right on the ones you keep. Then delete them. That's it, and it costs nothing.
>
> Sbu Clean finds duplicates, similar and blurry photos on your iPhone, lines up your screenshots and sorts videos from the heaviest. While it's at it, it merges contacts saved twice. You review the bin before anything goes, and iOS asks a second time.
>
> Many cleaner apps let you swipe for free, then ask for a subscription, weekly included, to unlock Delete. Here Delete is free.
>
> No subscription, no account, no ads, no tracking. Your photos stay on your iPhone.
>
> Link in bio: sbu.dev/apps/clean

## Bluesky @sbu.dev

IT (≤300):
> Sbu Clean è sull'App Store. Scorri le foto mese per mese, trova doppioni e video pesanti, elimina quante foto vuoi. Il tasto Elimina non costa niente e le foto non lasciano l'iPhone.
> sbu.dev/apps/clean

EN (≤300):
> Sbu Clean is on the App Store. Swipe through your photos month by month, find duplicates and heavy videos, delete as many as you like. Delete costs nothing and your photos never leave your iPhone.
> sbu.dev/en/apps/clean

## Reddit: r/iosapps

Un solo sub per il lancio. r/iosapps accetta lo sviluppatore che si dichiara (di solito con flair "Dev" o in un giorno dedicato). Regole lette in `reddit.md` il 18/10; **rileggere sidebar e regole il giorno stesso**, perché cambiano e non le abbiamo potute riscaricare il 22/11. Post di testo, non post-link. Non incollare lo stesso testo altrove. Rispondere a ogni commento per 24 ore.

Titolo: `[Dev] Sbu Clean: free photo cleaner, delete as many as you want, no subscription`

Testo:
> Disclosure: I made this.
>
> I got annoyed that the big photo cleaner apps let you swipe for half an hour and then put Delete behind a subscription. So I wrote one where deleting is free and has no daily limit.
>
> What it does: swipe left/right month by month (or Recent, Random, one album, On this day with a calendar), set unsure photos aside for later, duplicates, similar photos and similar videos found with Vision on the phone, blurry shots, photos saved from chat apps, screenshots in a grid, videos sorted by size with optional compression, Live Photos to stills, and duplicate contacts merged (a copy goes to Files first). You review a bin at the end and iOS asks for confirmation again. It also tells you that deleted photos stay 30 days in Recently Deleted, which is why the space often doesn't come back right away.
>
> No IAP, no account, no ads, no analytics, no server. Code is on GitHub: github.com/sbudotdev/apps/tree/main/Apps/SbuClean
>
> sbu.dev/apps/clean
>
> Happy to hear what's missing. It doesn't touch email or iCloud, on purpose.

## Show HN

Settimana del 23/11, il giorno in `calendario-lanci.md`, tra le 15 e le 17 ora italiana. Mai nella settimana di un altro Show HN, mai nel giorno di un invio ad Apple.

Titolo (≤80): `Show HN: I rebuilt a $11.99/week iPhone photo cleaner as a free app` (67)

Alternativa: `Show HN: Free iPhone photo cleaner where Delete isn't behind a paywall` (70)

Primo commento:
> Hi HN, I'm Matteo, a computer security student in Milan.
>
> Cleanup (737K ratings on the US App Store in October) lets you swipe through your library for free and then asks for a subscription to actually delete. The store lists weekly plans up to $11.99 (prices from the US listing, checked on [DATA]).
>
> Sbu Clean does the same job for free and without a daily limit: swipe keep/delete month by month or by "on this day", duplicates and similar photos found with Vision on the device (the best shot is preselected, never deleted on its own), similar videos, blurry shots, screenshots in a grid, videos sorted by size with compression, Live Photos to stills, and duplicate contacts merged after saving a copy to Files. You review a bin, and deletion goes through PhotoKit, so iOS shows its own confirmation. It also tells you that deleted photos sit in Recently Deleted for 30 days, which is why "the space didn't come back".
>
> Method: specs come only from public App Store data (listing, screenshots, reviews). Nothing decompiled. I built it with Claude and reviewed every line myself; Swift 6, SwiftUI, iOS 17+.
>
> Privacy: no account, no analytics, no ads, no server of mine. The only download is an iCloud original, and only when you ask to watch or compress it.
>
> What it does not do: email, iCloud "cleaning", AI enhance.
>
> It's one of [N, ricontare il giorno stesso: 7 al 22/11] free iPhone apps I have on the store at sbu.dev, each doing one thing with no subscription.
>
> Code: https://github.com/sbudotdev/apps/tree/main/Apps/SbuClean
> Page: https://sbu.dev/en/apps/clean

Risposte pronte: le 5 di `showhn.md` valgono ancora (nella numero 2 togliere la parentesi sulla repo: è pubblica).

## PR a open-source-ios-apps

Una PR per app (il maintainer non accetta PR multiple). Una sola PR aperta alla volta: si apre la successiva dopo il merge. Formato uguale alla #2446 (Scanner, fusa). Titolo: `Add Sbu Clean`.

Voce da aggiungere in fondo a `contents.json`:

```json
{
  "title": "Sbu Clean",
  "description": "Free up space in Photos: swipe to delete, duplicates found on the device, videos by size, no ads or tracking",
  "category-ids": ["photo"],
  "tags": ["swift", "swiftui"],
  "screenshots": [
    "https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/2f/ae/e3/2faee386-ba11-46e1-0939-d2a0758d69df/iPhone_17_Pro_Max-01-main_framed.png/320x480bb.jpg"
  ],
  "source": "https://github.com/sbudotdev/apps/tree/main/Apps/SbuClean",
  "itunes": "https://apps.apple.com/app/id6822655310",
  "license": "mit",
  "date_added": "[data del giorno]",
  "suggested_by": "@mgiuditta"
}
```

La PR a open-source-ios-apps punta a main, dove la 1.1 è fusa dal 22/11: la lista vuole un link stabile al codice.

Corpo della PR:
> Sbu Clean: free up space in the Photos library, free and open source SwiftUI (MIT). One entry in contents.json, follow-up to #2446.

## AlternativeTo

Voce nuova "Sbu Clean", alternativa a **Cleanup** (come la pagina sbu.dev/alternatives/cleanup). Categoria: Photos & Graphics. Licenza: Free, Open Source. Piattaforma: iPhone. Tag: photo-cleaner, duplicate-photos, duplicate-contacts, storage-cleaner, privacy, no-ads.

Descrizione breve (≤140):
> Free iPhone photo cleaner. Swipe to keep or delete, duplicates found on the device, videos by size. No subscription, no account.

Descrizione lunga:
> Sbu Clean frees up space in your iPhone's Photos library. Swipe left to bin a photo and right to keep it, month by month or one album at a time. It finds duplicates, similar photos, similar videos and blurry shots with Apple's Vision on the device, lines up screenshots in a grid, sorts videos from the heaviest with optional compression, and merges duplicate contacts after saving a copy to Files. Nothing is deleted until you review the bin, and iOS asks for confirmation again.
>
> Unlike most cleaner apps, deleting is free and has no daily limit. There is no in-app purchase, no account, no ads and no analytics, and the source code is public under MIT.
