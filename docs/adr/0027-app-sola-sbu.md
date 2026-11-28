# Un'app sola, «Sbu»: gli strumenti come pagine del Quaderno

**Stato: Proposto** (spike, SBU-464). Strada A scelta da Matteo il 27/11/2026 in SBU-461, dalla strategia di SBU-460.

Oggi ogni strumento sbu.dev è un'app a sé. Con la strada A c'è anche un'app sola, «Sbu» (`dev.sbu.sbu`), che li tiene tutti: la pagina iniziale è il Quaderno con gli strumenti che hai scelto, ognuno si apre a tutto schermo con la sua Cifra. Lo spike prova la strada con tre strumenti già in vendita: Level, Moon e Subscriptions.

## Decisione

- **Ogni strumento è una libreria statica costruita dai sorgenti della sua app**, senza copiarli. In `Apps/Sbu/project.yml` il target `LevelTool` include `../SbuLevel/SbuLevel` ed esclude solo ciò che è dell'app: il file con `@main`, i cataloghi di stringhe, l'asset catalog e il manifesto privacy. Lo stesso per `MoonTool` e `SubscriptionsTool`. È il modo più piccolo che regge:
  - una libreria è un modulo Swift suo, quindi i `RootView`, `MainView` e `NotificationAccess` delle tre app non si scontrano;
  - SbuKit si collega una volta sola, nell'app (`link: false` nelle librerie);
  - le app singole non cambiano di una riga.
- **Un file per strumento in `Apps/Sbu/Modules/<Strumento>`**: una vista pubblica (`LevelTool`, `MoonTool`, `SubscriptionsTool`) che mostra il `RootView` dell'app con quello che le dava il suo `App` (per Subscriptions il `ModelContainer` e gli oggetti d'ambiente), più l'`ImageResource` dell'icona nelle impostazioni.
- **Stringhe e risorse stanno nell'app Sbu**: il codice di una libreria cerca in `Bundle.main`. `Apps/Sbu/merge_strings.py` unisce le stringhe della shell (`Strings/Shell.xcstrings`) e i cataloghi delle tre app in `Sbu/Localizable.xcstrings`; la build fallisce se il file unito non è aggiornato. I JSON che le app leggono (città di Moon, catalogo e cambi di Subscriptions) sono inclusi dal loro percorso, non copiati.
- **La shell**: `Notebook` (elenco, aggiungi, togli, riordina, salvato nei default con la chiave `notebook.tools`), `Tool` (il catalogo degli strumenti), la pagina iniziale dentro `SbuAppShell` con le impostazioni condivise, il foglio «Strumenti» per modificarli, e `ToolPage`, che apre lo strumento a tutto schermo sotto una striscia «Quaderno» per tornare indietro (come le piattaforme di Social, ADR-0017: non copre mai il tasto indietro dello strumento). `sbu://<strumento>` apre uno strumento da un link o da una scorciatoia.
- **Niente modifiche a SbuKit né a `Design/tokens.json`** in questo spike (SBU-455 li sta toccando). Ciò che serve in comune sta nel target Sbu (per esempio `ForegroundNotificationPresenter`, uguale a quello di Moon e Subscriptions).

## Alternative scartate

- **Copiare i sorgenti nell'app Sbu**: due copie da tenere allineate, e i nomi uguali (`RootView`) si scontrano in un modulo solo.
- **Includere le cartelle direttamente nel target Sbu**: stesso scontro di nomi, senza moduli separati.
- **Un framework dinamico o un pacchetto Swift per strumento**: richiede di spostare il codice fuori dalle app e di rendere `public` i tipi che l'app usa. È il passo giusto se gli strumenti diventano molti, non per lo spike.
- **Restare solo con le app singole** (strada B di SBU-460): scartata da Matteo in SBU-461.

## Come si aggiunge uno strumento

1. In `Apps/Sbu/project.yml` un target `<Nome>Tool` con `templates: [Tool]`, i sorgenti `Modules/<Nome>` e la cartella dell'app con gli stessi `excludes`; aggiungerlo alle dipendenze di `Sbu`.
2. `Modules/<Nome>/<Nome>Tool.swift`: una vista pubblica che mostra il `RootView` dell'app con quello che le dà il suo `App`. Se l'app usa `ImageResource.appIconArtwork`, anche il file `ImageResource+Artwork.swift` e l'immagine `<Nome>Artwork` in `Sbu/Assets.xcassets`.
3. Il catalogo dell'app in `SOURCES` di `merge_strings.py`, poi `python3 Apps/Sbu/merge_strings.py`. I JSON o altre risorse lette con `Bundle.main` tra i `sources` del target Sbu.
4. Un caso nuovo in `Tool` (nome, riga, simbolo) e in `ToolPage`; le chiavi d'uso dei permessi nell'`Info.plist` di Sbu e la voce nel manifesto privacy, se lo strumento le usa.
5. Il test UI `testOpensEachToolFromTheNotebook` con il titolo dello strumento.

## Le app singole già in vendita

Restano in vendita e ricevono aggiornamenti come oggi: chi le ha comprate o scaricate non perde niente, e ogni correzione nella cartella dell'app arriva da sola anche in Sbu alla build successiva, perché il codice è lo stesso. I dati non passano da un'app all'altra: Sbu ha i suoi default e il suo archivio (vedi Passi futuri). Quando e se ritirare un'app singola lo decide Matteo, strumento per strumento.

## ASO

Sbu entra in App Store come app di utilità con un nome generico: non vince le ricerche per «livella», «fasi lunari» o «abbonamenti», che restano alle app singole. Le app singole portano le persone; Sbu è l'app per chi ne usa già più di una. Nome, sottotitolo e parole chiave di Sbu vanno scritti con il ticket di TestFlight e passano da Matteo.

## Permessi

Sbu non chiede niente all'avvio. Ogni permesso lo chiede lo strumento, con lo stesso codice dell'app, quando serve:

- **Level**: fotocamera solo quando apri il Mirino (`SightCamera`).
- **Moon**: notifiche solo quando attivi un avviso di fase (`PhaseAlerts`); posizione una volta, solo quando chiedi sorgere e tramonto (`DeviceLocation`).
- **Subscriptions**: notifiche solo quando attivi un promemoria (`Reminders`).

Le chiavi d'uso sono nell'`Info.plist` di Sbu, in italiano e in inglese (`InfoPlist.xcstrings`). Il manifesto privacy dichiara solo l'uso dei default (CA92.1), come le tre app; nessun dato raccolto, nessun tracciamento.

## Widget (non nello spike)

Un widget per strumento si farebbe con un'estensione WidgetKit sola in Sbu, con un widget per strumento nello stesso `WidgetBundle`: i target widget delle app (per esempio `SbuSubscriptionsWidget`) diventano librerie statiche come gli strumenti, oppure la loro cartella si include nell'estensione con gli stessi `excludes`. Dati condivisi tra app ed estensione con un App Group `group.dev.sbu.sbu`, come le app singole fanno con il loro.

## Passi futuri

- Subscriptions in Sbu oggi salva solo su questo iPhone: niente App Group, niente sincronizzazione iCloud, niente liste condivise (servono entitlement che Sbu non ha ancora). Vanno aggiunti prima di uscire dallo spike.
- Se gli strumenti diventano molti: un pacchetto Swift per strumento al posto delle cartelle incluse, e i pezzi comuni della shell (`Notebook`, `ToolPage`) in SbuKit, in un ticket a parte.
- Un'icona a celle per Sbu dopo SBU-455.
- TestFlight è il ticket successivo, dopo il QA.

## Conseguenze

- Una modifica a una delle tre app finisce anche in Sbu: i test di Sbu vanno lanciati anche quando si tocca Level, Moon o Subscriptions.
- Un tipo nuovo con lo stesso nome dentro due strumenti non dà problemi (moduli separati); un file nuovo con `@main` o una nuova risorsa letta da `Bundle.main` in un'app va escluso o aggiunto in `Apps/Sbu/project.yml`.
- Una chiave di stringa uguale in due strumenti con traduzioni diverse tiene la prima: `merge_strings.py` lo stampa a ogni build (oggi «Unità», Level e Subscriptions).
