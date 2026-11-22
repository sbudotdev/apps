# Lancio di Sbu Clean: kit

Stato il 22/11/2026: **1.1 (7) in vendita**, approvata da Apple il 22/11 (app 6822655310). Pagina: sbu.dev/apps/clean. Pagina alternativa online: sbu.dev/alternatives/cleanup (IT) e sbu.dev/en/alternatives/cleanup (EN). Date nel calendario: `marketing/calendario-lanci.md`.

Tutto qui è bozza: Matteo approva e pubblica. Materiale già scritto e ancora valido: `hooks.md`, `reddit.md`, `press.md`, `video.md` in questa cartella. Questo file sostituisce `showhn.md` per il primo commento (quello vecchio diceva "no contacts merge" e cita la repo come non ancora pubblica).

Prima di pubblicare qualsiasi testo con un prezzo: riaprire Cleanup su apps.apple.com (IT e US), aggiornare data e cifre qui e in `hooks.md`. I prezzi sotto sono di listino, letti il 15/10 e il 17/10. Sempre "fino a".

Cosa fa la 1.1 in vendita (dalla descrizione dello Store): scorri a sinistra per il cestino e a destra per tenere, mese per mese; doppioni e foto simili trovati con Vision sull'iPhone; screenshot in griglia; video dal più pesante, con compressione; Live Photo in foto; cestino con revisione finale e conferma di iOS; widget con lo spazio libero. Niente contatti, niente email.

## Instagram @sbudevapp

Immagine: primo screenshot dello Store (`iPhone_17_Pro_Max-01-main_framed`). Testo sull'immagine: "Elimina quante foto vuoi. Gratis."

IT:
> Scorri le foto, a sinistra quelle da buttare, a destra quelle da tenere. Poi le elimini. Tutto qui, e non costa niente.
>
> Sbu Clean trova doppioni e foto simili sull'iPhone, mette in fila gli screenshot e ordina i video dal più pesante. Prima di eliminare rivedi il cestino, e iOS chiede conferma una seconda volta.
>
> Molte app di pulizia ti fanno scorrere gratis e poi chiedono un abbonamento, anche settimanale, per il tasto Elimina. Qui il tasto Elimina è gratis.
>
> Niente abbonamento, niente account, niente pubblicità, niente tracking. Le foto restano sull'iPhone.
>
> Link in bio: sbu.dev/apps/clean

EN:
> Swipe left on the photos you don't want, right on the ones you keep. Then delete them. That's it, and it costs nothing.
>
> Sbu Clean finds duplicates and similar photos on your iPhone, lines up your screenshots and sorts videos from the heaviest. You review the bin before anything goes, and iOS asks a second time.
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
> What it does: swipe left/right month by month (or Recent, Random, On this day, one album), duplicates and similar photos found with Vision on the phone, screenshots in a grid, videos sorted by size with optional compression, Live Photos to stills. You review a bin at the end and iOS asks for confirmation again. It also tells you that deleted photos stay 30 days in Recently Deleted, which is why the space often doesn't come back right away.
>
> No IAP, no account, no ads, no analytics, no server. Code is on GitHub: github.com/sbudotdev/apps
>
> sbu.dev/apps/clean
>
> Happy to hear what's missing. It does photos and videos only, on purpose.

## Show HN

Settimana del 23/11, il giorno in `calendario-lanci.md`, tra le 15 e le 17 ora italiana. Mai nella settimana di un altro Show HN, mai nel giorno di un invio ad Apple.

Titolo (≤80): `Show HN: I rebuilt a $11.99/week iPhone photo cleaner as a free app` (67)

Alternativa: `Show HN: Free iPhone photo cleaner where Delete isn't behind a paywall` (70)

Primo commento:
> Hi HN, I'm Matteo, a computer security student in Milan.
>
> Cleanup (737K ratings on the US App Store in October) lets you swipe through your library for free and then asks for a subscription to actually delete. The store lists weekly plans up to $11.99 (prices from the US listing, checked on [DATA]).
>
> Sbu Clean does the same job for free and without a daily limit: swipe keep/delete month by month, duplicates and similar photos found with Vision on the device (the best shot is preselected, never deleted on its own), screenshots in a grid, videos sorted by size with compression, Live Photos to stills. You review a bin, and deletion goes through PhotoKit, so iOS shows its own confirmation. It also tells you that deleted photos sit in Recently Deleted for 30 days, which is why "the space didn't come back".
>
> Method: specs come only from public App Store data (listing, screenshots, reviews). Nothing decompiled. I built it with Claude and reviewed every line myself; Swift 6, SwiftUI, iOS 17+.
>
> Privacy: no account, no analytics, no ads, no server of mine. The only download is an iCloud original, and only when you ask to watch or compress it.
>
> What it does not do: contacts, email, iCloud "cleaning", AI enhance. Photos and videos only.
>
> It's one of seven free iPhone apps I have on the store at sbu.dev, each doing one thing with no subscription.
>
> Repo: https://github.com/sbudotdev/apps/tree/main/Apps/SbuClean
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
    "https://is1-ssl.mzstatic.com/image/thumb/PurpleSource211/v4/42/fd/fc/42fdfce0-885b-e311-d40a-d0f1fdff08ed/iPhone_17_Pro_Max-01-main_framed.png/320x480bb.jpg"
  ],
  "source": "https://github.com/sbudotdev/apps/tree/main/Apps/SbuClean",
  "itunes": "https://apps.apple.com/app/id6822655310",
  "license": "mit",
  "date_added": "[data del giorno]",
  "suggested_by": "@mgiuditta"
}
```

Corpo della PR:
> Sbu Clean: free up space in the Photos library, free and open source SwiftUI (MIT). One entry in contents.json, follow-up to #2446.

## AlternativeTo

Voce nuova "Sbu Clean", alternativa a **Cleanup** (come la pagina sbu.dev/alternatives/cleanup). Categoria: Photos & Graphics. Licenza: Free, Open Source. Piattaforma: iPhone. Tag: photo-cleaner, duplicate-photos, storage-cleaner, privacy, no-ads.

Descrizione breve (≤140):
> Free iPhone photo cleaner. Swipe to keep or delete, duplicates found on the device, videos by size. No subscription, no account.

Descrizione lunga:
> Sbu Clean frees up space in your iPhone's Photos library. Swipe left to bin a photo and right to keep it, month by month or one album at a time. It finds duplicates and similar photos with Apple's Vision on the device, lines up screenshots in a grid and sorts videos from the heaviest, with optional compression. Nothing is deleted until you review the bin, and iOS asks for confirmation again.
>
> Unlike most cleaner apps, deleting is free and has no daily limit. There is no in-app purchase, no account, no ads and no analytics, and the source code is public under MIT.
