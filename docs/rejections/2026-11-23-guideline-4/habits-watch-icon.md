# Sbu Habits: icona Apple Watch respinta (guideline 4, 23/11/2026)

**Messaggio di Apple.** «The app icon does not appear circular because your Apple Watch app icon's background color is black. Modify the app's Apple Watch app icon to include a lighter background color to ensure that it is recognizable and appears circular on Apple Watch.» Rimanda alla guideline 4 (Design) e alle HIG per watchOS. Nessun altro punto.

**Causa.** `make_icons.py --watch-appiconset` disegnava la variante scura (inchiostro chiaro su nero caldo). Sul quadrante nero del Watch il cerchio non si vede.

**Correzione** ([SBU-410](/SBU/issues/SBU-410)). L'icona Watch è l'icona iOS chiara (stesso inchiostro, carta, verde e griglia), rimpicciolita nel quadrato inscritto nel cerchio; la griglia continua fino al bordo. Regola aggiunta in `CLAUDE.md` (App icon grammar).

**Risposta nel Resolution Center.** «Updated the Apple Watch app icon with a light background so it reads as circular.»
