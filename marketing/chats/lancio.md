# Lancio di Sbu Chats: kit

Stato il 22/11/2026, 22:50: **1.0 (5) pronta su App Store Connect**, invio ad App Review previsto il 23/11 ([SBU-324](/SBU/issues/SBU-324)). App 6823369633. Non è in vendita: `apps.apple.com/app/id6823369633` oggi risponde 404. Pagina: sbu.dev/apps/chats (200). Nessuna pagina alternativa sul sito; la pagina dell'app indica l'app che rifà. Date nel calendario: `marketing/calendario-lanci.md`.

Tutto qui è bozza: Matteo approva e pubblica. **Si pubblica solo quando la 1.0 è `READY_FOR_SALE`** e il link dello Store risponde 200. Modello: `marketing/find/`.

Fatti (descrizione dello Store della 1.0, branch `paperclip/SBU-304-chats-fuel`, `Apps/SbuChats/fastlane/metadata/`): importa una chat esportata in .zip o .txt dal foglio di condivisione o da File; per ogni persona messaggi, parole, foto e video, conversazioni iniziate e chiuse, giorni di fila; tempo di risposta tipico e medio; grafici per ora, giorno, mese e anno; parole ed emoji più usate; ricerca, anche di una frase esatta; periodo a scelta; se riesporti la stessa chat aggiunge solo i messaggi nuovi; ogni statistica gratis, senza limiti di chat o di analisi al giorno; nessuna connessione a internet; una chat di esempio per provare subito.

Limite da dire: un export contiene al massimo circa 40.000 messaggi senza media (10.000 con i media), i più recenti. La storia cresce se riesporti più avanti (FAQ del sito).

**Il nome dell'app di messaggi non si scrive mai**, in nessun testo di questo kit: si dice "l'app di messaggi" o "una chat esportata". Vale anche per hashtag e testo sull'immagine. L'app a pagamento che Sbu Chats rifà ("The Cringe: Chat Wrapped", sulla pagina sbu.dev/apps/chats) si nomina solo su AlternativeTo, come fa il sito.

## Immagini

Gli screenshot framed della 1.0 (5) non sono nel repo (`.gitignore`: `**/fastlane/screenshots/**/*.png`). Oggi sono qui, nel worktree di [SBU-304](/SBU/issues/SBU-304), generati il 22/11 alle 22:14:

- IT: `/Users/matteo/dev/sbudotdev/apps-sbu-304/Apps/SbuChats/fastlane/screenshots/it/iPhone 17 Pro Max-01-chat_framed.png` ("I numeri della tua chat", 5350 messaggi della chat di esempio)
- EN: `/Users/matteo/dev/sbudotdev/apps-sbu-304/Apps/SbuChats/fastlane/screenshots/en-US/iPhone 17 Pro Max-01-chat_framed.png`
- Per il carosello Instagram, gli altri quattro della stessa cartella: `02-activity`, `03-words`, `04-chats`, `05-privacy`.

Se quel worktree è stato cancellato, si rigenerano con `fastlane screenshots` in `Apps/SbuChats` sul branch di SBU-304, oppure si prendono dallo Store dopo l'uscita (lookup `https://itunes.apple.com/lookup?id=6823369633&country=it`, campo `screenshotUrls`).

## Instagram @sbu_dev

Immagine: `01-chat_framed.png` IT. Carosello facoltativo con `02-activity` e `03-words`.

IT:
> Quanti messaggi vi siete scritti quest'anno? Chi risponde prima? A che ora parlate di più?
>
> Esporta una chat dall'app di messaggi e aprila con Sbu Chats. Vedi i messaggi e le parole di ognuno, il tempo di risposta, i grafici per ora e per giorno, le parole e le emoji più usate. Puoi anche cercare una frase in tutta la chat.
>
> Sbu Chats non va mai su internet. La chat resta sull'iPhone e la elimini quando vuoi. Dentro ci sono anche i messaggi degli altri, e restano lì.
>
> Ogni statistica è gratis, senza limiti di chat o di analisi al giorno.
>
> Niente abbonamento, niente account, niente pubblicità, niente tracking.
>
> Link in bio: sbu.dev/apps/chats

EN:
> How many messages did you send each other this year? Who replies faster? What time do you talk the most?
>
> Export a chat from your messaging app and open it in Sbu Chats. You see each person's messages and words, reply times, charts by hour and by day, the most used words and emoji. You can search the whole chat for a phrase, too.
>
> Sbu Chats never goes online. The chat stays on your iPhone and you delete it whenever you want. It holds other people's messages too, and they stay there.
>
> Every stat is free, with no limit on chats or analyses per day.
>
> No subscription, no account, no ads, no tracking.
>
> Link in bio: sbu.dev/en/apps/chats

## Bluesky @sbu.dev

IT (≤300):
> Sbu Chats è sull'App Store. Esporti una chat e vedi chi scrive di più, chi risponde prima, a che ora parlate. Tutto sull'iPhone, senza internet. Ogni statistica gratis, senza account.
> sbu.dev/apps/chats

EN (≤300):
> Sbu Chats is on the App Store. Export a chat and see who writes more, who replies faster, what time you talk. All on your iPhone, no internet. Every stat free, no account.
> sbu.dev/en/apps/chats

## Reddit: r/iosapps

Un solo sub, lo stesso di Clean: ammette post di sviluppatori sulle proprie app, se dichiarati. **Rileggere la sidebar il giorno stesso.** Se il post di Clean è uscito da meno di un mese, si salta: niente due post nello stesso sub così vicini.

Titolo: `I made a free chat stats app that never goes online: export a chat, get the numbers on your iPhone`

Testo:
> Disclosure: it's mine, it's free, no IAP.
>
> Chat stats apps are fun, but a chat export is about as private as data gets, and it holds other people's messages too. So Sbu Chats reads the export on the phone and has no network code at all.
>
> You share an exported chat (.zip or .txt) to the app. It shows each person's messages, words, media, who starts and ends conversations, longest streak, typical and average reply time, charts by hour, weekday, month and year, top words and emoji, and search. Export the same chat later and it adds only the new messages.
>
> Limit: an export holds roughly the latest 40,000 messages (10,000 with media), so older history only shows up if you exported it before.
>
> Swift 6, SwiftUI, code on GitHub: github.com/sbudotdev/apps
>
> sbu.dev/en/apps/chats

## Show HN

Non entra nel calendario fino al 15/12: le settimane libere sono già di Clean, Moon, Noise e della collezione. Va a gennaio, nella prima settimana libera dopo Level e Find (vedi `calendario-lanci.md`).

Titolo (≤80): `Show HN: Chat stats on iPhone from an exported chat, with no network code` (73)

Primo commento:
> Hi HN, I'm Matteo, a computer security student in Milan.
>
> Apps that show stats from your chats are popular. They ask you to hand over a chat export, which is some of the most private data on a phone and includes other people's messages.
>
> Sbu Chats parses the export on the device. You share a .zip or .txt from the messaging app's export, and it shows messages, words and media per person, who starts and ends conversations, streaks, typical and average reply time, activity by hour, weekday, month and year, top words and emoji, and full-text search. Re-export the same chat later and it merges only the new messages, so the history can grow past the export limit.
>
> The parser handles export formats in several languages and 12/24-hour times. If a file can't be read, it says why.
>
> What it does not do: read anything you don't share with it, sync, or back up. Exports cap at roughly the latest 40,000 messages without media.
>
> Method: specs come only from public App Store data (listings, screenshots, reviews). Nothing decompiled. Built with Claude, every line reviewed by me; Swift 6, SwiftUI, iOS 17+.
>
> Privacy: no account, no analytics, no ads, no network code.
>
> It's one of [N, ricontare il giorno stesso] free iPhone apps I have on the store at sbu.dev.
>
> Repo: https://github.com/sbudotdev/apps/tree/main/Apps/SbuChats
> Page: https://sbu.dev/en/apps/chats

Prima di pubblicare: controllare che `main` abbia il codice della versione in vendita (il branch di SBU-304 non è ancora fuso al 22/11; i suoi commit toccano build e screenshot).

Risposte pronte:

1. **"Which messaging apps?"**
   > Any whose chat export uses the same text format it parses. The page on sbu.dev lists how to export.
2. **"How do I know it doesn't upload?"**
   > The app has no network code, and the source is public. You can also run it in airplane mode.
3. **"Free means a paywall later."**
   > No IAP, no ads, no SDKs, no account. There's nothing to monetise. The code is public.

## PR a open-source-ios-apps

Una PR aperta alla volta, dopo quella di Noise. Titolo: `Add Sbu Chats`.

```json
{
  "title": "Sbu Chats",
  "description": "Stats from an exported chat, computed on the device with no network, no ads or tracking",
  "category-ids": ["misc"],
  "tags": ["swift", "swiftui"],
  "screenshots": ["[URL mzstatic del primo screenshot US, dal lookup dopo l'uscita]"],
  "source": "https://github.com/sbudotdev/apps/tree/main/Apps/SbuChats",
  "itunes": "https://apps.apple.com/app/id6823369633",
  "license": "mit",
  "date_added": "[data del giorno]",
  "suggested_by": "@mgiuditta"
}
```

## AlternativeTo

Voce nuova "Sbu Chats", alternativa a **The Cringe: Chat Wrapped** (come la pagina sbu.dev/apps/chats). Licenza: Free, Open Source. Piattaforma: iPhone. Tag: chat-statistics, privacy, offline, no-ads.

Descrizione breve (≤140):
> Stats from an exported chat on iPhone: messages, reply times, top words, charts. Works offline. Free, no ads.

Descrizione lunga:
> Sbu Chats turns an exported chat into numbers on your iPhone: messages, words and media for each person, who starts and ends conversations, reply times, charts by hour, weekday, month and year, the most used words and emoji, and search across every message.
>
> It never connects to the internet. Chats stay on the phone and you can delete them at any time. Every stat is free, with no limit on chats or analyses per day. There is no in-app purchase, no account, no ads and no analytics, and the source code is public under MIT.
