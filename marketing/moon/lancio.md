# Lancio di Sbu Moon: kit

Stato il 22/11/2026: **1.0 (2) in vendita**, approvata da Apple il 22/11 (app 6822656846). La 1.1 (4), con icona e screenshot nuovi, è in revisione dal 22/11: stesse funzioni. Pagina: sbu.dev/apps/moon. Pagina alternativa online: sbu.dev/alternatives/my-moon-phase-pro (EN: sbu.dev/en/alternatives/my-moon-phase-pro). Date nel calendario: `marketing/calendario-lanci.md`.

Tutto qui è bozza: Matteo approva e pubblica. Modello: `marketing/find/`.

Fatti (descrizione dello Store e pagina del sito): percentuale illuminata, la luna disegnata com'è, data e ora delle prossime quattro fasi, avvisi di fase (notifiche locali), sorgere e tramonto da posizione letta una volta o da una città, età e distanza dalla Terra, qualsiasi giorno dal 1900 al 2100. Calcolata sull'iPhone con gli algoritmi di Jean Meeus, senza rete: errore di qualche minuto sulle fasi, di pochi chilometri sulla distanza. My Moon Phase Pro costa 3,99 € (Store italiano, letto il 22/11 per la pagina del sito); ha in più le previsioni delle nuvole e le ore d'oro e blu, che Sbu Moon non ha perché non va mai in rete.

Aggancio di calendario: **luna piena il 24/11 e il 24/12**. L'ora esatta si legge in Sbu Moon il giorno prima e si mette nel post: è la prova che l'app serve.

## Instagram @sbudevapp

Immagine: primo screenshot dello Store, oppure uno screenshot dell'app con la luna piena del giorno. Testo sull'immagine: "Stasera luna piena. Te lo dice l'iPhone, senza rete."

IT:
> Stasera c'è la luna piena. Sbu Moon te lo dice senza connessione: calcola la luna sull'iPhone, con gli stessi algoritmi che usano gli astronomi.
>
> Apri l'app e vedi quanta luna è illuminata, se cresce o cala, quando arriva la prossima fase e a che ora sorge dove sei. Puoi guardare qualsiasi giorno dal 1900 al 2100 e farti avvisare prima della luna piena.
>
> L'app più conosciuta per le fasi lunari costa 3,99 €. Questa è gratis.
>
> Niente abbonamento, niente account, niente pubblicità, niente tracking. La posizione serve solo per il sorgere e il tramonto, se la chiedi, e resta sull'iPhone.
>
> Link in bio: sbu.dev/apps/moon

EN:
> Full moon tonight. Sbu Moon knows without a connection: it works out the moon on your iPhone, with the same algorithms astronomers use.
>
> Open the app and you see how much of the moon is lit, whether it's waxing or waning, when the next phase comes and when it rises where you are. You can look at any day from 1900 to 2100 and get an alert before the full moon.
>
> The best-known moon phase app costs $3.99. This one is free.
>
> No subscription, no account, no ads, no tracking. Location is used only for moonrise and moonset, if you ask, and stays on your iPhone.
>
> Link in bio: sbu.dev/en/apps/moon

Nota: "$3.99" va riletto sullo Store US prima di pubblicare (il sito ha solo il prezzo italiano). Se diverso, scrivere il prezzo US vero o togliere la frase. Nel post non si fa il nome dell'app a pagamento: il nome sta solo sulla pagina alternativa.

## Bluesky @sbu.dev

IT (≤300):
> Sbu Moon è sull'App Store. Fase, percentuale illuminata, prossima luna piena, sorgere e tramonto. Tutto calcolato sull'iPhone con gli algoritmi di Jean Meeus, senza rete. Gratis, senza account.
> sbu.dev/apps/moon

EN (≤300):
> Sbu Moon is on the App Store. Phase, percent lit, next full moon, moonrise and moonset. All worked out on your iPhone with Jean Meeus's algorithms, no network. Free, no account.
> sbu.dev/en/apps/moon

## Reddit: r/SideProject

Un solo sub. r/SideProject è fatto per mostrare un progetto proprio: la promozione è ammessa se il post racconta il progetto e non è solo un link. Regola generale del sub (da rileggere il giorno stesso nella sidebar: il 22/11 non abbiamo potuto scaricarla): post di testo, niente referral, rispondere ai commenti. Mai lo stesso testo in un altro sub.

Titolo: `I made a moon phase app that never touches the network. Meeus's algorithms, 1900 to 2100, on the phone`

Testo:
> Side project, free iPhone app, and yes it's mine.
>
> Most moon apps fetch data from somewhere. The moon doesn't need that: Jean Meeus published the algorithms in "Astronomical Algorithms", and a phone can run them in microseconds. So Sbu Moon computes everything locally: illumination, the next four phases, moonrise and moonset for your place (location read once, or pick a city), age and distance from Earth. Phases come out within a few minutes, distance within a few kilometres.
>
> You can scrub any day from 1900 to 2100 and set alerts for the phases you care about. They're local notifications, scheduled on the phone.
>
> What it doesn't do: clouds, weather, golden hour. Those need the network, and the app never goes online.
>
> No IAP, no account, no ads, no analytics. Swift 6 and SwiftUI, code on GitHub: github.com/sbudotdev/apps
>
> sbu.dev/en/apps/moon
>
> If you know a better test set than the published phase tables, I'd like to hear it.

## Show HN

Settimana in `calendario-lanci.md`, tra le 15 e le 17 ora italiana. Mai nella settimana di un altro Show HN, mai nel giorno di un invio ad Apple.

Titolo (≤80): `Show HN: Moon phases on iPhone, computed offline with Meeus's algorithms` (72)

Alternativa: `Show HN: A free moon phase app that never goes online` (53)

Primo commento:
> Hi HN, I'm Matteo, a computer security student in Milan.
>
> Moon phase apps on the App Store are often paid (the best known lists at €3.99 in Italy) or free with ads, and many fetch data from a server. None of that is needed: the moon's position is a solved problem. Jean Meeus's "Astronomical Algorithms" gives you phases, illumination, distance and rise/set times with formulas a phone runs instantly.
>
> Sbu Moon does exactly that, on the device: percent lit and the moon drawn as it looks, date and time of the next four phases, moonrise and moonset where you are (location read once at km precision, or a city from a bundled list), the moon's age and its distance from Earth, any day from 1900 to 2100. Phase alerts are local notifications. Phases come out within a few minutes of the published tables, distance within a few km. Times use the phone's time zone.
>
> What it does not do: clouds, weather, golden hour. Those need a network, and this app has no network code.
>
> Method: specs come only from public App Store data (listings, screenshots, reviews). Nothing decompiled. Built with Claude, every line reviewed by me; Swift 6, SwiftUI, iOS 17+.
>
> Privacy: no account, no analytics, no ads, no server.
>
> It's one of [N, ricontare il giorno stesso: 7 al 22/11] free iPhone apps I have on the store at sbu.dev, each doing one thing with no subscription.
>
> Repo: https://github.com/sbudotdev/apps/tree/main/Apps/SbuMoon
> Page: https://sbu.dev/en/apps/moon

Risposte pronte:

1. **"Why not use an ephemeris like JPL Horizons?"**
   > For a phone app showing phases to the minute, Meeus is plenty and needs no data files or network. If you need arcseconds you want a real ephemeris, not this app.

2. **"How did you test it?"**
   > Unit tests against the worked examples in Meeus's book (new moon from example 49.a, illumination from 48.a, distance and position from 47.a) and against USNO moonrise and moonset tables for real days. They're in the repo under Apps/SbuMoon/SbuMoonTests.

3. **"Moonrise is wrong for my town."**
   > Rise and set depend on your exact place and horizon. With a city from the list it uses that city's coordinates; use your location for better numbers. Tell me the place and date and I'll check.

4. **"Why does a moon app ask for location?"**
   > It doesn't, unless you turn on moonrise and moonset and choose "use my location". It reads it once, rounded to the kilometre, and keeps it on the phone. The phase itself is the same everywhere.

5. **"Free means a paywall later."**
   > No IAP, no ads, no SDKs, no account. There's nothing to monetise. The code is public.

## PR a open-source-ios-apps

Una PR per app, una aperta alla volta (si apre dopo il merge della precedente). Titolo: `Add Sbu Moon`.

```json
{
  "title": "Sbu Moon",
  "description": "Moon phase, next full moon, moonrise and moonset, computed on the device with no network, no ads or tracking",
  "category-ids": ["misc"],
  "tags": ["swift", "swiftui"],
  "screenshots": [
    "https://is1-ssl.mzstatic.com/image/thumb/PurpleSource211/v4/a5/7b/16/a57b16d9-f2d5-d56f-69fa-5cea2b5cb15e/iPhone_17_Pro_Max-01-main_framed.png/320x480bb.jpg"
  ],
  "source": "https://github.com/sbudotdev/apps/tree/main/Apps/SbuMoon",
  "itunes": "https://apps.apple.com/app/id6822656846",
  "license": "mit",
  "date_added": "[data del giorno]",
  "suggested_by": "@mgiuditta"
}
```

La lista non ha una categoria astronomia: `misc` è la più onesta. Se il maintainer ne suggerisce un'altra, si segue.

Corpo della PR:
> Sbu Moon: moon phases computed on the device, free and open source SwiftUI (MIT). One entry in contents.json.

## AlternativeTo

Voce nuova "Sbu Moon", alternativa a **My Moon Phase Pro** (come la pagina sbu.dev/alternatives/my-moon-phase-pro). Categoria: Education & Reference (astronomia). Licenza: Free, Open Source. Piattaforma: iPhone. Tag: moon-phase, astronomy, offline, privacy, no-ads.

Descrizione breve (≤140):
> Moon phase app for iPhone that works offline. Next phases, moonrise and moonset, alerts, 1900 to 2100. Free, no ads.

Descrizione lunga:
> Sbu Moon shows what the moon looks like right now: how much is lit, whether it is waxing or waning and when the next full moon comes. It lists the date and time of the next four phases, moonrise and moonset where you are, the moon's age and its distance from Earth, for any day from 1900 to 2100.
>
> Everything is computed on the iPhone with Jean Meeus's astronomical algorithms, with no network. Phase alerts are local notifications. There is no in-app purchase, no account, no ads and no analytics, and the source code is public under MIT. It has no cloud forecast or golden hour, because it never goes online.

## Aggiornamento 1.1 (4)

Stato: inviata il 22/11, in revisione. Il 22/11 alle 22:48 il lookup pubblico dello Store (IT e US) dà ancora la **1.0**. Lo stato ASC lo scrive [SBU-324](/SBU/issues/SBU-324). **Si pubblica solo quando la 1.1 è `READY_FOR_SALE`** e il lookup `https://itunes.apple.com/lookup?id=6822656846&country=it` risponde `"version":"1.1"`.

Novità (release notes inviate, branch `paperclip/SBU-267`): icona nuova, con l'alternativa Inversa nelle impostazioni, e schermate rifatte sul quaderno. Funzioni uguali alla 1.0. Non è un lancio: un post social, niente Show HN né Reddit. Se lo Show HN di Moon (2/12) esce con la 1.1 in vendita, il testo resta quello sopra.

Immagine: `/Users/matteo/dev/sbudotdev/apps-sbu-267/Apps/SbuMoon/fastlane/screenshots/it/iPhone 17 Pro Max-01-main_framed.png` (EN: stessa cartella con `en-US`). Generata il 22/11, worktree di [SBU-267](/SBU/issues/SBU-267), fuori dal repo: se manca, la si prende dallo Store dopo l'uscita.

Instagram IT:
> Sbu Moon ha un'icona nuova e le schermate rifatte. Se la preferisci chiara su fondo scuro, nelle impostazioni c'è l'icona Inversa.
>
> Il resto non cambia: la fase di stasera, le prossime quattro, il sorgere e il tramonto dove sei. Tutto calcolato sull'iPhone, senza rete.
>
> Gratis, senza account, senza pubblicità.
>
> Link in bio: sbu.dev/apps/moon

Instagram EN:
> Sbu Moon has a new icon and redrawn screens. If you'd rather have it light on dark, there's the Inversa icon in Settings.
>
> The rest is the same: tonight's phase, the next four, moonrise and moonset where you are. All worked out on your iPhone, with no network.
>
> Free, no account, no ads.
>
> Link in bio: sbu.dev/en/apps/moon

Bluesky IT (≤300):
> Sbu Moon 1.1 è sull'App Store: icona nuova, con l'alternativa Inversa nelle impostazioni, e schermate rifatte. Le fasi sono sempre calcolate sull'iPhone, senza rete.
> sbu.dev/apps/moon

Bluesky EN (≤300):
> Sbu Moon 1.1 is on the App Store: a new icon, with the Inversa alternate in Settings, and redrawn screens. Phases are still worked out on your iPhone, with no network.
> sbu.dev/en/apps/moon

Icona Inversa controllata il 22/11 (`AppIcon-Inversa.appiconset` sul branch di SBU-267): il cannocchiale disegnato chiaro su fondo nero.
