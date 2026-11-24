# Sbu Bar: Developer ID fuori dalla sandbox, API di sistema non documentate, nessuna rete

**Stato: Accettato** da Matteo il 24/11/2026.

Sbu Bar rifà gratis Bartender: nasconde, mostra e riordina le icone della barra dei menu del Mac, con profili e trigger (spec: `research/apps/bartender.md`, design: `docs/superpowers/specs/2026-11-24-sbu-bar-design.md`).

## Decisione

- **Distribuzione Developer ID con notarizzazione e .dmg da sbu.dev**, come Sbu Seasons (ADR-0022), non sul Mac App Store. Per leggere e spostare le icone delle altre app servono Accessibilità e Registrazione schermo fuori dalla sandbox. Nella sandbox resterebbe solo il separatore che nasconde: niente riordino delle icone altrui, niente barra separata, niente ricerca. La regola di parità con l'originale lo esclude.
- **API di sistema non documentate ammesse solo dove non c'è un'alternativa pubblica**, ognuna dietro un protocollo con una versione finta nei test. Ogni uso va elencato nel README dell'app, con cosa smette di funzionare se Apple la cambia. La spaziatura tra le icone (una preferenza globale non documentata) resta, con l'avviso che serve uscire e rientrare nell'account, e un tasto che ripristina il valore di sistema.
- **Nessuna rete**: niente aggiornamento automatico (Sparkle o simili), niente meteo, niente licenze. Unica eccezione: la mappa di sistema (MapKit) nel trigger Posizione, con puntina, raggio visibile e ricerca dell'indirizzo, come in Sbu Find. Tessere e ricerca vanno ai servizi di Apple, mai a sbu.dev o a terzi (deciso da Matteo il 24/11). Gli aggiornamenti si scaricano a mano dalla pagina dell'app su sbu.dev.
- **Clean room**: il codice nasce solo dalla spec di comportamento (scritta da fonti pubbliche) e dalla documentazione Apple. Nessun codice di Ice (GPL-3.0) o di altri progetti con licenze incompatibili con MIT. Le analisi del binario di Bartender, se esistono, restano private e fuori dai repo, e chi scrive il codice non le legge.

## Conseguenze

- Ogni versione di macOS va provata prima dell'uscita: le API non documentate possono rompersi.
- All'uscita, e se Sbu Bar si chiude, tutte le icone tornano visibili: niente resta nascosto senza l'app.
- Gli invii ad App Review non c'entrano: Sbu Bar non occupa lo slot settimanale. Ogni firma, notarizzazione e pubblicazione del .dmg passa comunque da Matteo.
