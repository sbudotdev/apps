# Instagram di sbu.dev (@sbu_dev)

Asset del profilo in inglese (SBU-386). Il profilo presenta tutto sbu.dev: app iPhone e Mac, giochi, strumenti per sviluppatori. Le regole dei contenuti sono in `../tiktok-instagram.md`, la bio anche in `../bio.md` («Instagram (EN)»). Lo stile è quello del quaderno: carta, reticolo, il punto fermo. Colori e font vengono solo da `Design/tokens.json` (tema chiaro) e `Design/fonts/`.

## Lista per pubblicare

**1. Modifica profilo**

- Foto: `profile-1080.png`
- Name (23/30): `sbu.dev · free software`
- Username: `sbu_dev`
- Category: `Software`
- Bio (125/150, contati anche i due a capo):
  ```
  Free software that replaces paid apps.
  iPhone and Mac apps, games, dev tools.
  No subscriptions, ads or tracking. Open source.
  ```
- Link 1: `https://sbu.dev`
- Link 2: `https://github.com/sbudotdev/apps`

**2. Post della griglia, in quest'ordine.** Instagram mette in alto a sinistra l'ultimo post pubblicato: così l'1 finisce lì.

1° `post-3-projects.png`
```
Seven iPhone apps on the App Store, Seasons and Prompter for Mac, a game and a server project on the way.
All of it is on sbu.dev, link in bio.
#iphone #freeapps #nosubscription #macapps
```

2° `post-2-promises.png`
```
No subscriptions, no ads, no tracking, in every project. The code is open.
Read it from the link in bio.
#iphone #freeapps #nosubscription #privacy
```

3° `post-1-intro.png`
```
Free software that replaces paid apps: iPhone and Mac apps, games and developer tools.
Everything is on sbu.dev, link in bio.
#iphone #freeapps #nosubscription #opensource
```

**3. Storie in evidenza.** Ogni Storia in evidenza si crea da una Storia già pubblicata. Quando la crei, in «Modifica copertina» scegli il file:

| Titolo | Copertina | Cosa ci va |
|---|---|---|
| Apps | `highlight-apps.png` | app iPhone e Mac |
| Games | `highlight-games.png` | i giochi (Squares) |
| Dev tools | `highlight-dev-tools.png` | SBU OS, template, Sbu Commerce |
| Open source | `highlight-open-source.png` | codice e GitHub |
| FAQ | `highlight-faq.png` | domande frequenti |

## Il quaderno della griglia (regola per tutti i post, anche quelli futuri)

Deciso da Matteo il 23/11/2026: la griglia del profilo è un unico quaderno a quadretti senza fine. Ogni post è un pezzo dello stesso foglio, e i quadretti continuano da un post all'altro.

- **Formato 1080×1440 (3:4).** È la forma con cui la griglia del profilo mostra i post: con un 4:5 Instagram taglierebbe i bordi.
- **Quadretto da 45 px, riga da 2 px nel colore `grid` (#e6e6de), su fondo `paper` (#f6f6f2).** 45 divide sia 1080 sia 1440: ogni post ha 24 × 32 quadretti, comincia su una riga e finisce su una riga.
- **La riga sta solo sul lato sinistro e su quello in alto di ogni quadretto.** Sul bordo destro e su quello basso il post non ha riga: la mette il post accanto, così sul bordo la riga non diventa doppia.
- **Fondo, colore e spessore della riga sono uguali in tutti i post.** Così il quaderno regge qualsiasi ordine, anche quando Instagram sposta tutta la griglia di una casella a ogni post nuovo.
- **Il contenuto resta dentro il suo post.** Niente testo o disegni a cavallo tra due post, perché lo spostamento di una casella li spezzerebbe. Continua solo il foglio.
- **Ogni post nuovo si fa in `source/instagram.html`**, con la classe `post paper`, e si controlla in `grid-preview.png`.

## File

| File | Misure | Cosa |
|---|---|---|
| `profile-1080.png` | 1080×1080 | Il marchio di `Design/logos/sbu-mark.svg` su un quadrato pieno di `ink`. La scritta è larga 708 px al centro, quindi il ritaglio a cerchio non la tocca. Si legge anche a 110 px. |
| `highlight-*.png` | 1080×1920 | Copertine: la parola sta nel cerchio centrale di 1080 px, l'unica parte che Instagram mostra |
| `post-1-intro.png` | 1080×1440 (3:4) | Il marchio e «Free software that replaces paid apps.» |
| `post-2-promises.png` | 1080×1440 (3:4) | La cifra 0 e le promesse: no subscriptions, no ads, no tracking, open source |
| `post-3-projects.png` | 1080×1440 (3:4) | Tutti i progetti, ognuno con icona, nome, piattaforma e stato |
| `grid-preview.png` | 3246×1440 | I tre post affiancati come nel profilo, con 3 px di stacco: serve a controllare che i quadretti combacino |
| `source/instagram.html` | | Sorgente unico, con un frame per file (`?f=<nome>`) |
| `source/render.py` | | Esporta i PNG |

`post-3-projects` mostra i progetti di `docs/stato.md` (22/11) che sono anche sul sito, con lo stato al 23/11/2026:
- le 7 app sullo Store, verificate con il lookup pubblico (`itunes.apple.com/lookup`): Subscriptions, Scanner, Find, Moon, Clean, Level, Noise;
- Seasons, scaricabile per Mac;
- Prompter, per Mac e iPhone, distribuita su GitHub;
- Squares, il gioco in sviluppo;
- Sbu Commerce, il server in costruzione.

Chats e Fuel non sono ancora pubblicate, quindi mancano. SBU OS e i template mancano perché non sono né in `stato.md` né sul sito. Sbu Commerce non ha un'icona incisa: al suo posto c'è una casella di carta con il punto fermo nel suo accento (`accent-commerce`).

## Riesportare i PNG

Dalla radice della repo `apps`:

```sh
python3 marketing/social/instagram/source/render.py                    # tutti
python3 marketing/social/instagram/source/render.py post-3-projects    # uno solo
```

Servono Google Chrome (headless) e ImageMagick (`magick`). Dopo i post rifà anche `grid-preview.png`. Lo script avvia un server locale su una porta libera scelta dal sistema, lo spegne alla fine e controlla le misure di ogni PNG.

Quando un progetto cambia stato, aggiorna la sua casella nel frame `post-3-projects` e riesporta. Il post già pubblicato resta com'è.
