# Icone a celle: lo strumento è disegnato a quadretti, il punto fermo è l'unica cella colorata

Sostituisce la regola delle icone incise (ADR-0013, «Le icone app restano incise»). Scelta di Matteo il 27/11/2026 tra quattro direzioni (SBU-452, SBU-453): **B · Quaderno a celle**.

L'icona è una pagina del quaderno di Sbu. Su una griglia fissa di 12×12 celle lo strumento dietro l'app è fatto di celle piene in `ink`, dentro le colonne 1–9 e le righe 1–10 (contando da 0), con al massimo 40 celle. Il **Punto fermo** è l'unica cella colorata, sempre la cella (10,10), nell'accento dell'app. Le varianti escono dalla stessa pagina:

- **Chiaro:** celle `ink` su `paper`, con le linee `grid`.
- **Scuro:** celle chiare (`ink` scuro) su nero caldo, il punto nell'accento scuro.
- **Tinted:** celle bianche su nero e il punto in grigio, così iOS lo tinge e il punto resta distinto dal disegno.
- **Inversa**, l'unica icona alternativa: celle `paper` su `ink`, il punto in `accent-on-ink-*`.
- **Mac:** il chiaro nel quadrato arrotondato di Big Sur. **Watch:** il chiaro rimpicciolito nel quadrato sicuro del cerchio, mai su fondo scuro (rifiuto del 23/11/2026, SBU-409).

I disegni stanno in `Design/icons/cells.json`, 12 righe di `.` e `#` per app, versionati come testo; gli accenti restano in `Design/icons/engravings.json`. `Tools/make_icons.py` produce tutte le varianti e controlla le regole (griglia, colonne, righe, 40 celle); `Tools/test_make_icons.py` verifica le regole, i colori di ogni variante e che nessuna app abbia lo stesso disegno di un'altra. Clean (un cestino) e Tidy (una scopa) non condividono più il soggetto.

Niente modelli generativi nelle icone. Le incisioni (`Design/icons/source/`, ora prodotte da `Tools/engrave.py`) restano come tavole accanto alla colonna di sbu.dev, nelle anteprime Open Graph e nelle slide: sono illustrazioni, non icone. Le liste delle app sul sito usano `Design/icons/sbu-*.png` e mostrano le icone a celle dal primo deploy dopo il merge.

Uscita: nessuna review Apple dedicata. Ogni app riceve l'icona a celle con il suo prossimo aggiornamento già in programma (`make_icons.py <app> --appiconset … --artwork … --inverse …`, più `--watch-appiconset` o `--mac-appiconset` dove servono); Seasons e Prompter con la prossima `.dmg`. Per qualche settimana sullo Store ci saranno icone incise e a celle insieme.

Motivo: le icone incise erano belle a 1024 px e illeggibili a 60, 40 e 29 pt (il tratteggio diventa grigio), il punto fermo cambiava misura e posizione da un'app all'altra, in tinted il punto spariva nel disegno e due app avevano la stessa scopa. A celle ogni icona si legge a 29 pt, è coerente con il design system v5 per costruzione («il punto fermo è l'unica cella piena») e un'icona nuova costa minuti, senza Gemini né ritocchi. Il prezzo è il fascino dell'incisione e qualche soggetto ridotto a simbolo (Prompter, Remote, Libretto). Alternative scartate: A «Incisione netta» (resta debole a 29 pt e legata a Gemini), C «Elementi» (due lettere non dicono cosa fa l'app, testo nell'icona contro le HIG) e D «Campo pieno» (rompe «inchiostro, non colore» e somiglia a tutte le app di utilità).
