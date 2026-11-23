# Instagram di sbu.dev (@sbudevapp)

Asset del profilo in inglese (SBU-386). Nome, categoria, bio e link sono in `../bio.md`, sezione «Instagram (EN)»; le regole dei contenuti in `../tiktok-instagram.md`. Stile quaderno: carta, reticolo, una cifra per post, il punto fermo. Colori e font solo da `Design/tokens.json` (tema chiaro) e `Design/fonts/`.

## File

| File | Misure | Cosa |
|---|---|---|
| `profile-1080.png` | 1080×1080 | Foto profilo: `Design/logos/sbu-mark.svg` su un quadrato pieno di `ink`, scritta larga 708 px al centro, così il ritaglio a cerchio non la tocca. Si legge a 110 px. |
| `highlight-apps.png` | 1080×1920 | Copertina Storie in evidenza «Apps» |
| `highlight-free.png` | 1080×1920 | Copertina «Free» |
| `highlight-privacy.png` | 1080×1920 | Copertina «Privacy» |
| `highlight-behind-the-scenes.png` | 1080×1920 | Copertina «Behind the scenes» |
| `highlight-faq.png` | 1080×1920 | Copertina «FAQ» |
| `post-1-intro.png` | 1080×1350 (4:5) | Cifra 1: «Free iPhone apps that do one thing.» |
| `post-2-promises.png` | 1080×1350 (4:5) | Cifra 0: le sette promesse |
| `post-3-apps.png` | 1080×1350 (4:5) | Cifra 7: le app oggi sullo Store, con l'icona vera e il punto fermo nell'accento di ognuna |
| `captions.md` | | Didascalie EN dei tre post |
| `source/instagram.html` | | Sorgente unico, un frame per file (`?f=<nome>`) |
| `source/render.py` | | Esporta i PNG |

Nelle copertine la parola sta al centro del cerchio di 1080 px che Instagram mostra.

## Riesportare i PNG

```sh
python3 marketing/social/instagram/source/render.py                 # tutti
python3 marketing/social/instagram/source/render.py post-3-apps     # uno solo
```

Dalla radice della repo `apps`. Serve Google Chrome (headless) e ImageMagick (`magick`). Lo script avvia un server locale su una porta libera scelta dal sistema, lo spegne alla fine e controlla le misure di ogni PNG.

`post-3-apps` elenca le app in vendita il 23/11/2026, verificate con il lookup pubblico dell'App Store (`itunes.apple.com/lookup`): Subscriptions, Scanner, Find, Moon, Clean, Level, Noise. Chats e Fuel non risultano ancora pubblicate. Quando esce un'app nuova si aggiungono la sua icona (`Design/icons/sbu-<app>.png`) e il suo accento (`accent-<app>`) nel frame `post-3-apps`, si cambia la cifra e si riesporta; il post già pubblicato resta com'è.

## Ordine di pubblicazione

Instagram mette in alto a sinistra l'ultimo post. Per avere la cifra 1 lì:

1. `post-3-apps`
2. `post-2-promises`
3. `post-1-intro`

Prima dei post: foto profilo, nome, bio e link da `../bio.md`. Le copertine si usano quando si crea ogni Storia in evidenza. La pubblicazione la fa Matteo.
