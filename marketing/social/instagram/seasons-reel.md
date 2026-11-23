# Reel di Sbu Seasons (v2: la cosa imbarazzante in piccolo)

v2 · 23 novembre 2026 · dal piano di SBU-400 §5. Sostituisce l'idea di SBU-121: la chiave falsa **non** è più a tutto schermo. Il protagonista è il desktop del Mac con la neve; il codice imbarazzante sta in piccolo, in un angolo. È il primo esempio della meccanica «easter egg» di `crescita.md` §4.

## Lo schermo

Un desktop normale e ordinato: una finestra del browser, una delle Note, il Dock. In alto a destra, piccola e mezza coperta, una finestra dell'editor con `app/page.tsx`: la chiave API in chiaro nel frontend, `dangerouslyAllowBrowser: true` e il commento `// TODO: move to the server before launch`. A grandezza normale sembra solo codice; chi ingrandisce o mette in pausa la legge.

Il file è pronto sul Mac di Matteo: `~/Desktop/seasons-post/app/page.en.tsx`, con le istruzioni di registrazione in `~/Desktop/seasons-post/LEGGIMI.md`. Il file italiano `page.tsx` della v1 resta lì com'era.

## La chiave falsa, in inglese, in un angolo

Il profilo è in inglese, quindi la chiave nasconde una frase inglese con lo stesso gioco della v1:

| Inizio | Frase nascosta | Fine |
|---|---|---|
| `sk-proj-` | `1fY0uR34dTh1sY0uTh1nk1m54nt4` | `T3BlbkFJ` |

Nel file sono attaccati, in una stringa sola. La frase si legge «if you read this you think I'm Santa». Ha l'inizio e la fine delle chiavi vere, ma è falsa e non funziona. Qui è scritta in tre pezzi perché il controllo dei segreti di GitHub la scambierebbe per una chiave vera e bloccherebbe il push: la stringa intera sta solo in `~/Desktop/seasons-post/app/page.en.tsx`.

## La scheda del browser

Seconda traccia, piccola: il titolo di una scheda del browser, **«how to remove api key from git history»**. Per chi guarda bene, è la stessa storia.

## Scaletta

15-18 s. 9:16 per Instagram, 4:5 per LinkedIn.

| Tempo | Schermo | Testo sopra |
|---|---|---|
| 0-3 s | Desktop, Seasons spenta | «Paid apps charge up to €10 for snow on your Mac.» |
| 3-10 s | Si accende Seasons: la neve cade, si posa sulle finestre e sul Dock, il cursore la sposta | «This one is free.» |
| 10-15 s | Passa Babbo Natale con la slitta | «No account. No ads. Open source.» |
| 15-18 s | Chiusura sbu.dev su carta | «Sbu Seasons for Mac. sbu.dev/seasons» |

Nessuno zoom sull'angolo: chi lo trova deve trovarlo da solo.

Nel 9:16 la registrazione è larga circa un terzo dell'originale. Per questo l'editor usa un carattere di 16-18 pt: è ancora una grandezza normale, non uno zoom, e la riga della chiave resta leggibile in pausa. Prima dell'ok di Matteo si controlla un fotogramma in pausa sul telefono.

## Didascalia (EN)

```
Someone showed me an app that makes it snow on your Mac. Up to €10.

We made one for free: Sbu Seasons. Snow settles on your windows and on the Dock, you push it around with the cursor, and now and then Santa flies by. No account, no ads, open source.

Idea by Simone Antoniciello. Link in bio.

One thing on this screen should not be there. Did you spot it?

#mac #macos #opensource #christmas
```

Gli hashtag sono quelli del piano per un'app Mac: qui non valgono i tre fissi `#iphone #freeapps #nosubscription` di `../tiktok-instagram.md` §4.

## Dove

- Reel su @sbu_dev in collaborazione con il profilo personale di Matteo.
- Post LinkedIn di Matteo in 4:5, con il testo già approvato in SBU-121 (ultima riga adattata all'angolo).

## Dopo la pubblicazione

- Non spieghiamo l'easter egg nella didascalia.
- Al primo commento che lo trova rispondiamo: «Took you a while. It's fake. Read it again.» e lo fissiamo in alto.
- Il tag di Simone lo mette Matteo a mano.
- Nella prima ora rispondiamo a tutti i commenti (`crescita.md` §4).
- Il lunedì dopo scriviamo i numeri del Reel in `marketing/log.md`.

La pubblicazione la approva Matteo (SBU-307), come tutti i post sui suoi profili.

## Montaggio

Il progetto è in `seasons-reel/` (HyperFrames). Una sola composizione 1080×1920: testi e registrazione stanno nella fascia centrale 1080×1350, che è anche la zona che i pulsanti di Reels non coprono. Il 4:5 per LinkedIn è quella fascia, ritagliata dallo stesso render.

- La registrazione non viene mai tagliata (si vede intera, con l'angolo in alto a destra), su fondo carta con il reticolo del quaderno.
- I testi sono in Bricolage Grotesque, colori `ink` e `paper` di `Design/tokens.json`.
- Il video è muto: Seasons non ha suoni e i Reel non usano musica con licenza (`../tiktok-instagram.md` §5).

**Quando arriva la registrazione:**

1. Copia l'MP4 di Matteo in `seasons-reel/input/seasons.mp4`. È l'unico file da cambiare.
2. Dalla radice della repo `apps`:
   ```sh
   sh marketing/social/instagram/seasons-reel/render.sh
   ```
   Escono `seasons-reel/renders/seasons-reel-9x16.mp4` (1080×1920) e `seasons-reel-4x5.mp4` (1080×1350). Alla fine lo script stampa misure e durata di tutti e due con `ffprobe`.
3. Se la registrazione parte lenta, alza `data-media-start` del `<video>` in `seasons-reel/index.html` (secondi da saltare). Il montaggio usa 15 s di registrazione, poi 3 s di chiusura.

Servono Node (`npx hyperframes`), ffmpeg e la rete: GSAP (3.14.2, versione fissa) arriva da jsDelivr. `input/` e `renders/` non vanno nel repo (`seasons-reel/.gitignore`). Per controllare il progetto prima di rendere: `npx hyperframes check marketing/social/instagram/seasons-reel`.
