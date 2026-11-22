# Lancio di Sbu Noise: kit

Stato il 22/11/2026: **1.0 (3) in vendita**, approvata da Apple il 22/11 (app 6822655015). La 1.1 (5), con icona e screenshot nuovi, è in revisione dal 22/11: stesse funzioni. Pagina: sbu.dev/apps/noise. **Nessuna pagina alternativa** sul sito: nei testi non si fa il nome di nessuna app a pagamento. Date nel calendario: `marketing/calendario-lanci.md`.

Tutto qui è bozza: Matteo approva e pubblica. Modello: `marketing/find/`.

Fatti (descrizione dello Store e codice): 34 suoni in loop, cioè rumori colorati generati e registrazioni CC0 da Freesound (pioggia, acqua, natura, casa, viaggio); preferiti e Gestisci; Mix fino a cinque suoni con volume separato e suono intorno a te in cuffia; timer che sfumano, ripetuti nei giorni scelti; sveglia che sale piano, con il suono che vuoi e Posponi; orologio da comodino con luminosità regolabile; suona a schermo bloccato, AirPlay, comandi delle cuffie; widget, Centro di Controllo, Comandi Rapidi e Siri. Senza rete.

Onestà sul prodotto: è un'app per addormentarsi con un suono, non una terapia. Mai "cura l'insonnia", "dormi meglio garantito", "scientificamente provato".

## Instagram @sbudevapp

Immagine: primo screenshot dello Store. Testo sull'immagine: "Pioggia, mare, ventilatore. Gratis, senza rete."

IT:
> Scegli un suono e dormi. Pioggia, mare, un ventilatore, rumore bianco o rosa. Sbu Noise continua a suonare a schermo bloccato, anche in modalità aereo.
>
> Puoi mescolare fino a cinque suoni, ognuno con il suo volume. Il timer sfuma piano, così il silenzio non ti sveglia. Al mattino c'è una sveglia che sale piano, con il suono che scegli tu.
>
> 34 suoni, nessuno a pagamento. Le registrazioni sono CC0, cioè libere per tutti.
>
> Niente abbonamento, niente account, niente pubblicità, niente tracking.
>
> Link in bio: sbu.dev/apps/noise

EN:
> Pick a sound and sleep. Rain, the sea, a fan, white or pink noise. Sbu Noise keeps playing with the screen locked, even in airplane mode.
>
> Mix up to five sounds, each with its own volume. The timer fades out slowly, so the silence doesn't wake you. In the morning an alarm fades in, with the sound you choose.
>
> 34 sounds, none behind a paywall. The recordings are CC0, free for anyone.
>
> No subscription, no account, no ads, no tracking.
>
> Link in bio: sbu.dev/en/apps/noise

## Bluesky @sbu.dev

IT (≤300):
> Sbu Noise è sull'App Store. 34 suoni per dormire, rumori colorati e registrazioni CC0, da mescolare fino a cinque. Timer che sfuma, sveglia che sale piano. Funziona senza rete. Nessun suono a pagamento.
> sbu.dev/apps/noise

EN (≤300):
> Sbu Noise is on the App Store. 34 sleep sounds, colored noise and CC0 recordings, mix up to five. A timer that fades out, an alarm that fades in. Works offline. No sound behind a paywall.
> sbu.dev/en/apps/noise

## Reddit: r/sleep, solo come risposta

Un solo sub. r/sleep tratta il sonno, non le app: un post di lancio verrebbe letto come pubblicità. Si risponde solo a thread dove qualcuno chiede un'app di suoni o di rumore bianco senza abbonamento, con il consiglio prima del link e dichiarando che l'app è tua. **Rileggere sidebar e regole il giorno stesso** (il 22/11 non abbiamo potuto scaricarle): se la self-promotion è vietata anche nei commenti, si salta r/sleep e si usa r/iosapps con il modello di Clean, un'altra settimana.

Thread da cercare: "white noise app without subscription", "best free sleep sounds app iPhone", "rain sounds app no ads".

Risposta modello (EN):
> A tip first: pick a sound without a melody or obvious loop point, and set a timer that fades out instead of stopping dead. The sudden silence is what wakes a lot of people.
>
> If you want an app for it, I made a free one (disclosure: it's mine, no IAP, no account, no ads): 34 sounds, mostly CC0 recordings from Freesound plus white/pink/brown noise, mix up to five, fading timer, works in airplane mode. sbu.dev/en/apps/noise

## Show HN

Settimana in `calendario-lanci.md`, tra le 15 e le 17 ora italiana. Mai nella settimana di un altro Show HN, mai nel giorno di un invio ad Apple.

Titolo (≤80): `Show HN: Sleep sounds for iPhone with CC0 recordings, offline, no subscription` (78)

Alternativa: `Show HN: A free white noise app with no network code` (52)

Primo commento:
> Hi HN, I'm Matteo, a computer security student in Milan.
>
> Sleep sound apps are one of the busiest corners of the App Store, and most of the popular ones lock part of the library behind a subscription. The job is small: loop a sound well, let it run with the screen locked, fade out at the end.
>
> Sbu Noise does that for free. 34 looping sounds: white, pink and brown noise generated on the device, a few synthesized sounds (wind, drops, air conditioner, plane cabin), and CC0 recordings from Freesound (rain, water, nature, home, travel), each credited in the app even though CC0 doesn't require it. You can mix up to five with separate volumes, spatialized in headphones. Timers fade out and can repeat on chosen days; the alarm fades in with the sound you pick, with snooze; there's a dim bedside clock. It plays in the background, with AirPlay, headphone controls, a widget, Control Center, Shortcuts and Siri.
>
> On iOS 26 the alarm is backed by a system alarm, in case the app isn't open when it goes off; before iOS 26 it falls back to a local notification.
>
> Method: specs come only from public App Store data (listings, screenshots, reviews). Nothing decompiled. Built with Claude, every line reviewed by me; Swift 6, SwiftUI, iOS 17+.
>
> Privacy: no account, no analytics, no ads, no server. The app has no network code; all sounds ship in the bundle.
>
> It's one of seven free iPhone apps I have on the store at sbu.dev, each doing one thing with no subscription.
>
> Repo: https://github.com/sbudotdev/apps/tree/main/Apps/SbuNoise
> Page: https://sbu.dev/en/apps/noise

Risposte pronte:

1. **"There are already free white noise apps."**
   > Yes, several, usually with ads or a locked library. This one has neither, and the code and sound credits are public. If you're happy with yours, keep it.

2. **"How do you avoid an audible loop point?"**
   > Recordings: a window is cut from the CC0 source and the seam is folded with an equal-power crossfade, then loudness-matched (EBU R128, same level for every sound so mixing needs no volume fiddling). Synthesized sounds are built to be periodic over the loop length, so there's no seam at all. The script is in the repo: Apps/SbuNoise/SoundTools/make_sounds.py.

3. **"Why CC0 only?"**
   > So anyone can fork the repo and ship it without a licence headache. The credits are in the app anyway.

4. **"Does it drain the battery overnight?"**
   > It's audio playback with the screen off, which iOS handles efficiently. Test it on your phone and tell me what you see.

5. **"Free means a paywall later."**
   > No IAP, no ads, no SDKs, no account. There's nothing to monetise. The code is public.

## PR a open-source-ios-apps

Una PR per app, una aperta alla volta (si apre dopo il merge della precedente). Titolo: `Add Sbu Noise`.

```json
{
  "title": "Sbu Noise",
  "description": "Sleep sounds and white noise, CC0 recordings, mixes, fading timers and alarm, offline, no ads or tracking",
  "category-ids": ["audio"],
  "tags": ["swift", "swiftui"],
  "screenshots": [
    "https://is1-ssl.mzstatic.com/image/thumb/PurpleSource221/v4/6d/2f/3a/6d2f3af6-c341-7e0d-874c-45310d49dc68/iPhone_17_Pro_Max-01-main_framed.png/320x480bb.jpg"
  ],
  "source": "https://github.com/sbudotdev/apps/tree/main/Apps/SbuNoise",
  "itunes": "https://apps.apple.com/app/id6822655015",
  "license": "mit",
  "date_added": "[data del giorno]",
  "suggested_by": "@mgiuditta"
}
```

Corpo della PR:
> Sbu Noise: sleep sounds and white noise, free and open source SwiftUI (MIT), CC0 recordings. One entry in contents.json.

## AlternativeTo

Voce nuova "Sbu Noise". Il sito non ha una pagina alternativa per Noise, quindi nella descrizione nessun nome di altre app. Il campo "alternativa a" di AlternativeTo lo sceglie Matteo tra le voci già presenti nella categoria (suoni per dormire, rumore bianco) al momento dell'invio. Categoria: Audio & Music. Licenza: Free, Open Source. Piattaforma: iPhone. Tag: white-noise, sleep-sounds, ambient-sounds, offline, no-ads.

Descrizione breve (≤140):
> Free sleep sounds for iPhone: 34 loops, CC0 recordings, mix up to five, fading timer and alarm. Works offline, no ads.

Descrizione lunga:
> Sbu Noise plays a sound to sleep to and keeps going with the screen locked. It has 34 looping sounds: white, pink and brown noise plus CC0 recordings of rain, water, nature, home and travel. You can mix up to five sounds with separate volumes, set timers that fade out and repeat on chosen days, and wake up to an alarm that fades in with the sound you pick. There is a dim bedside clock, a widget, Control Center, Shortcuts and Siri.
>
> It works without a network. There is no in-app purchase, no account, no ads and no analytics, and the source code is public under MIT.
