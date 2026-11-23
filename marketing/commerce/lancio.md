# Lancio di Sbu Commerce v0.1.0: kit

Stato il 23/11/2026: **v0.1.0 pubblicata**. Repo https://github.com/sbudotdev/commerce (pubblica, MIT, 0 stelle il 23/11). Release https://github.com/sbudotdev/commerce/releases/tag/v0.1.0 (pubblicata il 23/11 alle 11:27 UTC, non prerelease). CI della repo pubblica verde sul commit `cd09b1b` (run 45165376540, job `test` e `compose`). Fonte: [SBU-362](/SBU/issues/SBU-362). Pagina del sito: sbu.dev/software/commerce (200), oggi dice ancora «In costruzione». Date nel calendario: `marketing/calendario-lanci.md`.

Tutto qui è bozza: **Matteo approva e pubblica**. Niente è uscito.

## Fatti (README e CHANGELOG della v0.1.0)

Cosa fa:
- backend e-commerce open source per il B2B, licenza MIT, self-hosted: si installa sui propri server con Docker, nessuno lo ospita per te né tiene i tuoi dati; nessuna edizione a pagamento con funzioni chiuse;
- parla la REST API che gli storefront esistenti già usano: lo storefront di riferimento open source, cambiando **solo l'URL base**, naviga il catalogo demo e riempie un carrello anonimo (prova nel browser con screenshot in `docs/m1` della repo, nessuna richiesta con 4xx o 5xx);
- catalogo: contesto del sito (lingue inglese e italiano, valuta EUR), pagine CMS fisse, lista per categoria, ricerca libera con suggerimenti, paginazione, ordinamento per rilevanza, nome o prezzo, filtro per categoria, breadcrumb, pagina prodotto con prezzo, disponibilità e immagini;
- carrello anonimo: crea, aggiungi, cambia quantità, togli, totali in EUR;
- catalogo demo inventato: 50 prodotti in 8 categorie, in inglese e italiano;
- `docker compose up --build` avvia Postgres e l'API sulla porta 9002; CI con test HTTP su Postgres vero e con l'immagine Docker;
- scritto solo da materiale pubblico: codice dello storefront open source (Apache 2.0) e documentazione e specifica OpenAPI pubbliche.

Cosa **non** fa ancora (da dire sempre): login e utenti registrati, checkout, pagamento, ordini, tasse, promozioni, account B2B. Prossimo traguardo: M2, utenti registrati e login (`docs/ROADMAP.md`, «proposta, non iniziato»). Il `compose.yaml` è una demo locale, non per la produzione.

**Mai nominare la piattaforma commerciale né lo storefront di riferimento**, in nessun testo, hashtag o immagine (ADR-0016, piano §2 vincolo 8). Si dice «gli storefront esistenti», «lo storefront di riferimento open source», «le piattaforme e-commerce enterprise a licenza». Non si promettono date, clienti o migrazioni.

## Immagini

In questa cartella, prese dalla prova nel browser della release (`docs/m1`, 1440×900, catalogo inventato, nessun marchio di terzi):
- `flusso-v0.1.0.gif`: i 9 passi del flusso (home, categoria, suggerimenti, risultati, prodotto, aggiunta, carrello, quantità 2, carrello vuoto), 960 px, ~1,7 s a fotogramma, 197 KB;
- `2-category.png`: categoria «Lighting» con prezzi in EUR;
- `3-search-suggestions.png`: suggerimenti mentre si scrive «lamp»;
- `7-cart.png`: carrello con un prodotto e totale.

Lo storefront nelle immagini è quello di riferimento, senza modifiche al suo aspetto: la GIF mostra che risponde Sbu Commerce, non un design di sbu.dev. Per un post su LinkedIn va bene la GIF; per Bluesky `2-category.png` + `7-cart.png`.

## LinkedIn (profilo di Matteo)

Il canale principale: parla a sviluppatori, agenzie e chi decide in azienda (pubblico E del piano). Immagine: `flusso-v0.1.0.gif`.

IT, lungo:
> Ho pubblicato la prima versione di Sbu Commerce: un backend e-commerce per il B2B, open source con licenza MIT.
>
> Lavoro da anni su piattaforme e-commerce enterprise che costano licenze molto care. Sbu Commerce prova un'altra strada: parla la stessa REST API che gli storefront esistenti già usano, così uno storefront può cambiare backend cambiando solo l'URL.
>
> Cosa fa la v0.1.0, oggi:
> · catalogo con categorie, ricerca con suggerimenti, pagina prodotto con prezzo e disponibilità
> · carrello anonimo: aggiungi, cambia quantità, togli, totali in EUR
> · uno storefront open source, con solo l'URL base cambiato, naviga il catalogo demo e riempie il carrello
> · si avvia con `docker compose up --build`, sui tuoi server
>
> Cosa non fa ancora: login, checkout, ordini, pagamento, account B2B. Il prossimo passo è il login.
>
> Self-hosted, nessuna edizione a pagamento, nessun dato che passa da noi. È scritto solo da documentazione e codice pubblici.
>
> Codice e release: github.com/sbudotdev/commerce
>
> Se lavori su un e-commerce B2B e vuoi provarlo o dirmi cosa manca, scrivimi.

IT, corto:
> Sbu Commerce v0.1.0 è uscita: backend e-commerce B2B open source (MIT), self-hosted con Docker. Parla la REST API degli storefront esistenti: uno storefront open source, cambiando solo l'URL, naviga il catalogo e riempie il carrello. Login, checkout e ordini non ancora.
> github.com/sbudotdev/commerce

EN, lungo:
> I've released the first version of Sbu Commerce: an open source B2B e-commerce backend, MIT licensed.
>
> I've spent years on enterprise e-commerce platforms with very expensive licences. Sbu Commerce tries another way: it speaks the same REST API existing storefronts already use, so a storefront can switch backend by changing only its base URL.
>
> What v0.1.0 does today:
> · catalog with categories, search with suggestions, product page with price and stock
> · anonymous cart: add, change quantity, remove, totals in EUR
> · an open source storefront, with only its base URL changed, browses the demo catalog and fills the cart
> · runs with `docker compose up --build`, on your own servers
>
> What it doesn't do yet: login, checkout, orders, payment, B2B accounts. Login is next.
>
> Self-hosted, no paid edition, no data passing through us. Written only from public documentation and public code.
>
> Code and release: github.com/sbudotdev/commerce
>
> If you work on B2B e-commerce and want to try it or tell me what's missing, get in touch.

EN, corto:
> Sbu Commerce v0.1.0 is out: an open source (MIT) B2B e-commerce backend you self-host with Docker. It speaks the REST API existing storefronts use: an open source storefront, with only its base URL changed, browses the catalog and fills a cart. No login, checkout or orders yet.
> github.com/sbudotdev/commerce

## Bluesky @sbu.dev e X

Immagini: `2-category.png`, `7-cart.png`. Un post, nessun thread.

IT:
> Sbu Commerce v0.1.0: backend e-commerce B2B open source (MIT), sui tuoi server con Docker.
> Parla la REST API degli storefront esistenti: cambi solo l'URL e il catalogo e il carrello rispondono.
> Login, checkout e ordini arrivano dopo.
> github.com/sbudotdev/commerce

EN:
> Sbu Commerce v0.1.0: an open source (MIT) B2B e-commerce backend, on your own servers with Docker.
> It speaks the REST API existing storefronts use: change the base URL and the catalog and cart answer.
> Login, checkout and orders come later.
> github.com/sbudotdev/commerce

Instagram @sbu_dev: no. Parla a chi usa le app, non a chi sceglie un backend.

## Riga per il sito (sbu.dev/software e /software/commerce)

Oggi la pagina dice «In costruzione». Proposta (la modifica al sito è un ticket a parte):
- IT: «v0.1.0 è uscita: catalogo, ricerca e carrello anonimo, sui tuoi server con Docker. Login, checkout e ordini non ancora. Codice e release su GitHub.»
- EN: «v0.1.0 is out: catalog, search and an anonymous cart, on your own servers with Docker. No login, checkout or orders yet. Code and release on GitHub.»
- Etichetta in `/software`: «In costruzione» → «v0.1.0» (EN «Under construction» → «v0.1.0»), link a github.com/sbudotdev/commerce.

## Community di sviluppatori (dopo, non in questa tornata)

- **Show HN**: non con la v0.1.0. Le quattro settimane libere fino al 15/12 sono già di Clean, Moon, Noise e della collezione (una a settimana), e senza login né checkout il primo commento sarebbe «non si può comprare niente». Proposta: Show HN quando c'è un ordine completo (checkout e ordini, roadmap «Later»), oppure a gennaio con M2, in una settimana senza altri Show HN. Titolo di partenza: «Show HN: Sbu Commerce, an open source commerce backend that speaks existing storefronts' REST API».
- **Reddit** r/selfhosted e r/opensource: con lo Show HN, da uno a tre giorni dopo, come le app.
- **Articolo tecnico** (piano §1, 90 giorni): «Cambiare backend a uno storefront cambiando solo l'URL», su sbu.dev e LinkedIn, con i numeri della prova M1 (`docs/m1`). Da scrivere quando Matteo approva i post di questa tornata.

## Dopo la pubblicazione

- Una riga in `marketing/log.md` per ogni post, lo stesso giorno, con le stelle: `gh api repos/sbudotdev/commerce --jq .stargazers_count`.
- Rispondere a ogni commento tecnico; le richieste di funzioni vanno in issue su `sbudotdev/commerce`.
