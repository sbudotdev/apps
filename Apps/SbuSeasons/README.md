# Sbu Seasons ❄︎

App Mac nella barra dei menu, pensata per più stagioni e temi: neve, primavera, estate, autunno, pioggia sul vetro, temporale, nebbia, nuvole,
lucciole, stelle cadenti e sereno.
Nasce da un'idea di Simone Antoniciello (MGS-421).

Neve che cade sopra tutte le finestre del Mac, **si accumula sul bordo superiore delle finestre**
e sopra il Dock, e col cursore la sposti e la sparpagli.

**Permessi.** Nessuno per la neve e l'accumulo sulle finestre. Con il permesso Accessibilità
(Impostazioni di Sistema → Privacy e sicurezza) la neve si posa anche sul Dock e segue gli angoli
più stondati delle app con barra strumenti. Se il Dock si nasconde o sta di lato, sul fondo non si posa niente.
L'app non è nella sandbox: senza, macOS non darebbe né le finestre delle altre app né l'Accessibilità.

La neve si posa sempre sul bordo superiore di una finestra, mai più in basso. Se tra il bordo e la barra dei menu
non c'è posto per il mucchio (finestre ingrandite, quelle attaccate alla barra, app a schermo intero), quella finestra
non prende neve e i fiocchi cadono più giù, fino a un'altra finestra, al Dock o al fondo (SBU-101).

La neve si posa solo sulle finestre vere di macOS, non su pannelli e modali che le app disegnano come finestre a sé
(la ricerca di IntelliJ, palette di comandi, popover). Con il permesso Accessibilità restano solo le finestre con
subrole `AXStandardWindow` (via dialoghi, pannelli, sheet). Senza permesso, o se l'app non risponde, una finestra
che sta tutta dentro una finestra più grande della stessa app conta come modale. Nessuna eccezione per singole app.
Una modale non prende neve, ma copre ancora il tratto di bordo che ha davanti: la neve non le finisce sopra.
A batteria va a 30 fotogrammi al secondo invece di 60, per consumare meno.
Con **Riduci movimento** di macOS (Accessibilità → Schermo) va anche lei a 30 fotogrammi, cade metà dei fiocchi,
senza vento, oscillazione né rotazione, e gli oggetti non si lanciano e non rimbalzano: cadono dritti.
L'impostazione si segue anche mentre l'app è aperta.

**Pausa automatica.** Quando un'app a schermo intero copre uno schermo (un video, una presentazione) l'effetto su
quello schermo si ferma e sparisce, e riparte quando l'app esce dallo schermo intero; quando i display dormono si ferma
su tutti (SBU-177). Prima la neve restava visibile anche sopra le app a schermo intero.

Requisiti: macOS 14+, Xcode 26+, XcodeGen (`brew install xcodegen`).

## Novità della 2.1

- **Sfondi per ora del giorno:** ogni sfondo del borgo in otto momenti (alba, aurora, mattina, mezzogiorno, ora d'oro,
  tramonto, crepuscolo, notte), segue l'ora del Mac o resta fisso su un momento. Il cambio lo fa macOS, anche ad app chiusa.
- **Lo sfondo segue l'effetto:** cambiando effetto arriva lo sfondo consigliato, su tutti gli schermi.
- **Salvaschermo** con gli sfondi del borgo e l'effetto sopra, da installare dalle Impostazioni.
- **Novità:** dopo un aggiornamento, la prima volta che apri il menu ❄︎, una schedina con le cose nuove.

I dettagli sono in «Sfondi per ora del giorno e salvaschermo (2.1)».

## Novità della 2.0

- **Stagioni nuove:** pioggia sul vetro, temporale, nebbia, nuvole, lucciole, stelle cadenti e sereno; l'intensità ora ha anche un cursore continuo.
- **Giocare con la neve:** palle di neve da lanciare, pupazzo, neve che scivola dalle finestre, palla di vetro da scuotere,
  spazzaneve, slittino, funivia e albero di Natale.
- **Natale:** Babbo Natale con la slitta, omino di pan di zenzero, conto alla rovescia.
- **Personaggi e notte:** volpe, cincia, baita, lanterna, renna; la notte con la candela.
- **Sfondi e suoni:** dieci sfondi "Il borgo" (anche per schermi ultrawide) e suoni brevi creati a codice, spenti finché non li accendi.
- **Menu rifatto** con un tour di benvenuto e l'opzione «Dietro le finestre».
- Si clicca solo sugli oggetti, il resto dello schermo resta tuo; con Riduci movimento tutto si calma.

I dettagli sono nelle sezioni (2.0) qui sotto.

## Provarla mentre la sviluppi

```bash
cd Apps/SbuSeasons
xcodegen                                   # genera SbuSeasons.xcodeproj da project.yml
xcodebuild test -scheme SbuSeasons -destination 'platform=macOS'
open SbuSeasons.xcodeproj                  # schema SbuSeasons, destinazione My Mac, ▶︎
```

Il progetto Xcode non è nella repo: si rigenera con `xcodegen` dopo ogni cambio a `project.yml` o ai file.

## Costruire l'app

```bash
xcodebuild -scheme SbuSeasons -configuration Release -derivedDataPath build build
open build/Build/Products/Release/SbuSeasons.app
```

Senza `SBU_TEAM_ID` la firma è "ad-hoc": va bene sul tuo Mac, ma macOS chiede di nuovo il permesso
Accessibilità dopo ogni build. Per darla ad altri servono la firma Developer ID e la notarizzazione,
con il download da sbu.dev (ADR-0022, `docs/adr/0022-app-mac.md`).

## Il .dmg da distribuire

```bash
./make-dmg.sh 2.0.3  # → build/dist/SbuSeasons-2.0.3.dmg
```

Build Release universale (arm64 + x86_64), firma Developer ID, `.dmg` con il collegamento ad Applicazioni,
notarizzazione e `stapler staple`; alla fine `spctl` deve dire `Notarized Developer ID`.
Usa `SBU_TEAM_ID` e la chiave API di App Store Connect di fastlane (`ASC_KEY_PATH`, `ASC_KEY_ID`, `ASC_ISSUER_ID`).
Le versioni sono nelle [release della repo](https://github.com/sbudotdev/SbuSeasons/releases); l'ultima è la [2.0.3](https://github.com/sbudotdev/SbuSeasons/releases/tag/v2.0.3).

**2.0.1 (9).** Uguale alla 2.0, con il credito nuovo: "Nata da un'idea di Simone Antoniciello" (SBU-93).

**2.0.2 (10).** La neve non scende più sotto il bordo delle finestre ingrandite (se non c'è posto sotto la barra dei menu
non si posa) e si posa solo sulle finestre vere di macOS, non su modali, palette e dialoghi delle app (SBU-101).

**2.0.3 (11).** «Metti in pausa i giochi» ora tiene: la slitta in volo sparisce e non ne parte un'altra. Babbo Natale chiamato
dal menu ripassa da solo ogni pochi minuti e attraversa tutti gli schermi, uno dopo l'altro (SBU-114).

**1.3.1.** La 1.3 crashava all'avvio su un MacBook (la 1.2 partiva). La 1.3.1 toglie la novità della 1.3
(un display link per schermo con `SKRenderer`, MGS-636) e torna alla `SKView` della 1.2 (MGS-686).
Con due monitor a frequenze diverse (per esempio 144 e 60 Hz) la neve torna lenta su uno dei due:
la correzione dei due monitor si rifà in un ticket a parte.

**1.4 (7).** La neve va alla stessa velocità su due monitor a frequenze diverse, senza toccare la `SKView` (SBU-19).
SpriteKit chiamava `update` solo sulla scena dello schermo più lento: sull'altro la neve si fermava,
o andava a metà velocità a batteria. Ora ogni finestra prende un display link dalla sua `SKView`,
che segue il suo schermo, e muove lei la scena (`SeasonScene.step(at:)`); la `SKView` disegna come nella 1.2.
Il test `TwoScreensTests` lo prova con uno schermo virtuale a una frequenza diversa da quello principale.

**2.0 (8).** Oggetti con cui giocare sopra le finestre, stagioni nuove, Natale, personaggi, sfondi, suoni e menu nuovo
(SBU-49…SBU-57, vedi «Novità della 2.0»). Rilasciata da `main` (SBU-72).

## Giocare con la neve (2.0)

- **Palle di neve.** Tieni premuto ⌥ e passa il cursore sulla neve posata: la neve raccolta sparisce dal bordo e,
  quando basta (`Tuning.snowballSnow`, circa 15 cm di finestra piena), sotto il cursore nasce una palla. Si prende
  e si lancia col mouse, rimbalza un po' e rotola lungo i bordi finché cade. Al massimo 12 sullo schermo: oltre
  sparisce la più vecchia. Solo d'inverno: cambiando stagione palle e pupazzi si sciolgono.
- **Pupazzo.** Tre palle ferme a meno di 40 pt l'una dall'altra diventano un pupazzo di neve. Una palla in mano non conta.
- **Neve che scivola via.** Se sposti piano una finestra la neve resta sopra e la segue; se la trascini veloce
  (più di 40 pt in un ottavo di secondo, circa 320 pt/s) o la ridimensioni, la neve scivola giù come polvere.
  La neve segue la finestra a scatti, 8 volte al secondo: tante sono le letture delle finestre.
- **Palla di vetro.** Scuoti il cursore o una finestra (o «Scuoti la palla di vetro» nel menu): tutta la neve posata
  si alza, i fiocchi salgono, le palle saltano, poi tutto ricade. Dopo una scossa riposa 3 s. Con Riduci movimento no.
  Mentre tieni ⌥ (d'inverno) il cursore non scuote: passare avanti e indietro sulla neve per raccoglierla non deve portarla via.
- Menu: «Togli le palle di neve» toglie le palle sciolte (i pupazzi restano); «Sciogli la neve» toglie anche palle e pupazzi.
- **Spazzaneve** («Manda lo spazzaneve»). Con «Prima il Dock» (acceso all'inizio) parte dal Dock, se no dalla finestra
  più in alto. Va verso destra a 150 pt/s e raccoglie la neve sotto di sé, che cresce davanti alla lama; finito un bordo
  cade su quello sotto e continua, fino al fondo e fuori dallo schermo. Lì la neve raccolta resta: una montagnetta
  (al massimo 6). Uno alla volta.
- **Slittino** («Prepara la pista da slittino»). Compare in cima alla finestra più in alto (senza finestre, sul fondo).
  Lo lanci trascinandolo, o un clic lo spinge avanti; frena pochissimo, quindi arriva in fondo al bordo e scende sul
  prossimo: la pista sono i bordi delle finestre. Al massimo 3.
- **Funivia** («Monta la funivia»). Un palo sul fondo a sinistra e un gancio d'ottone col cavo: trascina il gancio sul
  bordo di una finestra (o sul Dock) e la cabina corre avanti e indietro sul cavo. Se la finestra si sposta il gancio cade
  e la cabina torna al palo. «Togli la funivia» la smonta. Una per schermo.
- **Albero di Natale** («Pianta un albero di Natale»). Sul fondo, in un punto a caso; un clic su un ramo appende una
  pallina proprio lì (colori a turno, al massimo 40), e si trascina come gli altri oggetti. Al massimo 5 alberi.
- «Togli alberi, neve e slitte»: alberi, montagnette, slittini e spazzaneve (palle e funivia hanno il loro comando).
  «Metti in pausa i giochi»: gli oggetti stanno fermi dove sono e non si prendono col mouse; la neve continua. La slitta in
  volo sparisce e non ripassa, le altre voci dei giochi si spengono finché non togli la pausa; la pausa resta anche quando
  le finestre si ricreano (monitor collegato, risveglio). Cambiando stagione si toglie.
- I giochi si fanno sullo schermo del cursore; lo spazzaneve con «Prima il Dock» su quello del Dock. Solo d'inverno:
  nelle altre stagioni le voci sono spente e cambiando stagione i giochi spariscono.
- Suoni: vedi «Sfondi e suoni».

## Meteo (SBU-177)

Le funzioni meteo di KoiArt che mancavano, rifatte (comportamento, non codice né disegni: tutto è disegnato a codice).
Niente rete, niente permessi in più, nessun dato che esce dal Mac.

- **Foglie** (autunno). Si ammucchiano sui bordi come prima; passando col cursore sul mucchio le foglie si staccano
  intere (una ogni tre granelli di neve, `Tuning.leafPieceShare`), ognuna col colore di una foglia vera, girano
  e volano via in alto e di lato, poi planano giù. La neve invece si sbriciola in polvere come prima.
- **Petali** (primavera). Non fanno più mucchio: ogni petalo che si posa su una finestra (o sul Dock) resta lì intero,
  adagiato, per 20–45 s (`SpringTuning.linger`), poi sfuma in 3 s. Al massimo 60 per finestra. Il cursore li porta via,
  e se la finestra si sposta piano restano sopra; se si sposta veloce o si chiude volano via.
- **Lucciole**. Quando il cursore sta fermo da 1,5 s (`Tuning.gatherDelay`) si radunano piano attorno a lui, ognuna
  alla sua distanza (18–70 pt), girandoci intorno; appena il cursore si muove di più di 4 pt si disperdono.
- **Stelle cadenti**. Quando la testa di una stella tocca il bordo scoperto di una finestra (o il Dock) si rompe in
  14 scintille che volano a ventaglio, ricadono e si spengono in meno di un secondo.
- **Pioggia**. Anche nella pioggia sul vetro ogni 40–120 s un lampo lontano, più tenue del temporale (`RainTuning.lightning`),
  poi il tuono se i suoni sono accesi.
- **Arcobaleno dopo la pioggia** (Impostazioni → Meteo, acceso di base). Quando si passa da pioggia o temporale a un altro
  effetto (dal menu, dalle Impostazioni o col meteo a caso), su ogni schermo sale un arcobaleno tenue dietro a tutto:
  entra in 4 s, resta e sfuma negli ultimi 8 s, in tutto 40 s.
- **Meteo a caso** (Impostazioni → Meteo, spento di base). L'effetto cambia da solo ogni 10–25 minuti
  (`Tuning.weatherShuffle`), con una dissolvenza di 1,2 s per lato. La regola (`WeatherShuffle`, emisfero nord):
  dicembre–febbraio neve, nebbia, nuvole, stelle cadenti; marzo–maggio primavera, pioggia, temporale, nuvole, nebbia;
  giugno–agosto estate, lucciole, stelle cadenti, temporale, nuvole; settembre–novembre autunno, pioggia, nebbia, nuvole,
  temporale. Mai il sereno (non cade niente) e mai lo stesso effetto due volte di fila. Lasciando la neve i giochi
  d'inverno spariscono, come cambiando effetto a mano.
- **Mucchi più alti** (Impostazioni → Meteo). L'altezza massima dei mucchi × 2,5 (`Tuning.tallSnowFactor`), sulle finestre
  e sul Dock; una finestra troppo vicina alla barra dei menu per il mucchio più alto non prende neve, come prima.
- **120 fps sugli schermi ProMotion** (Impostazioni → Meteo, spento di base). Solo sugli schermi che li fanno, a corrente
  e senza Riduci movimento: a batteria e con Riduci movimento restano 30.
- **Pausa automatica**: vedi in cima.
- Con **Riduci movimento**: le lucciole si radunano a metà velocità e senza girare, foglie e petali staccati cadono
  invece di volare via e non girano, le stelle fanno un terzo delle scintille, ferme, che si spengono dove sono, niente lampi,
  l'arcobaleno compare e sparisce senza dissolvenza, il meteo a caso cambia senza dissolvenza.

Il codice: `Engine/Weather.swift` (meteo a caso, cursore fermo, bordo toccato, schermo coperto), `Engine/Sparks.swift`,
`Engine/Rainbow.swift`, i petali posati in `Pile` (`rest`, `age`), il resto in `SeasonScene.step`. Le stagioni dicono
cosa fanno con `Season.pieceSize`, `linger`, `gathers`, `shatters`. I numeri in `Tuning.swift`, sezione «Meteo».

**CPU** (SBU-177, Release, schermo 1920×1080, tre finestre e il Dock, intensità Media, `main` e il branch alternati, 18 giri
ciascuno, mediana del tempo di CPU di un passo della simulazione). Non si è lanciata l'app sul Mac condiviso: la simulazione
gira in un test, uguale nelle due versioni. Neve 0,0398 → 0,0396 ms (−0,8%), autunno 0,0660 → 0,0649 (−1,7%),
primavera 0,0656 → 0,0651 (−0,7%), pioggia 0,0721 → 0,0725 (+0,6%), lucciole 0,0082 → 0,0056, stelle 0,0030 → 0,0033 ms
(+0,0003 ms a passo, meno dello 0,002% di un core a 60 fps). Con il disegno fuori schermo (texture della scena a ogni passo)
lucciole, stelle e pioggia stanno entro ±6%, la primavera scende del 31% (i petali posati sono sprite fermi, il mucchio era
una forma da ridisegnare); neve e autunno saltano fra 0,55 e 2,5 ms a fotogramma in tutte e due le versioni, quindi lì
la misura col disegno non dice niente. Va rifatta con l'app vera, come nelle sezioni sopra.

## Meteo, secondo giro (SBU-185)

Altre funzioni di KoiArt, rifatte a modo nostro. Niente rete, nessun permesso in più: il fulmine sul Dock usa l'Accessibilità
che serve già per la neve sul Dock.

- **Vento** (Impostazioni → Caduta). Il cursore va da ← 80 a 80 →: a sinistra o a destra, da brezza a forte. Il vento
  soffia sempre dallo stesso lato, con raffiche che scendono fino al 60% (`Tuning.windGustDip`). I valori salvati
  prima (0…80) restano validi: soffiano verso destra.
- **Vento variabile** (Impostazioni → Meteo, spento di base). Si alza, si calma e gira ogni 3 minuti
  (`Tuning.variableWindPeriod`, un giro intero in 6), con la forza del cursore e almeno 30 pt/s.
  Con Riduci movimento niente vento, come prima.
- **Pausa quando giochi a un videogioco** (Impostazioni → Energia, accesa di base). Quando un'app viene davanti,
  `VideoGame` guarda la sua categoria (`LSApplicationCategoryType` che inizia con `public.app-category.` e finisce con
  `games`) e il percorso (`/steamapps/`, i giochi di Steam). Se è un gioco, l'effetto si ferma e sparisce su tutti gli schermi,
  Babbo Natale e gli altri visitatori non passano, e l'app smette anche di leggere le finestre. Riparte quando torni a
  un'altra app. È un'altra cosa da «Metti in pausa i giochi», che ferma solo gli oggetti di Sbu Seasons.
- **Energia** (Impostazioni → Energia). «Ferma a batteria» (spento di base) ferma tutto quando stacchi la corrente.
  Con Risparmio energetico, o quando il Mac si scalda (`thermalState` `.serious` o `.critical`), particelle, banchi e
  gocce sul vetro si dimezzano da soli (`Tuning.energyShare`), e tornano pieni quando passa.
- **Schermi** (Impostazioni → Schermi, solo con più di uno schermo). Un interruttore per schermo; la scelta si salva
  per schermo (lo stesso UUID con cui la galleria ricorda gli sfondi), quindi resta anche staccando e riattaccando il monitor.
- **Finestre pulite** (Impostazioni → Meteo, spento di base). La neve su finestre e Dock si scioglie piano, 2 pt al secondo
  (`Tuning.cleanMeltRate`), e resta uno strato sottile di 3 pt (`Tuning.cleanLayer`). «Sulle finestre» spento la toglie
  tutta, come prima.
- **Segui la stagione** (Impostazioni → Meteo, spento di base). Sceglie l'effetto dal calendario (`SeasonCalendar`):
  dicembre–febbraio neve, marzo–maggio primavera, giugno–agosto estate, settembre–novembre autunno. Non si somma a
  «Meteo a caso»: accenderne uno spegne l'altro. Se scegli a mano un effetto fuori stagione, «Segui la stagione» si spegne.
- **Schizzi**. Nel temporale una goccia su tre che arriva sul bordo scoperto di una finestra o sul Dock schizza in 5
  goccioline basse che durano meno di mezzo secondo (`Tuning.splashShare`, `splashDrops`); le altre cadono davanti.
  Anche le gocce che scorrono sul vetro schizzano quando arrivano su un bordo. Con Riduci movimento due goccioline ferme.
- **Fulmine sul Dock**. Con pioggia o temporale, quando chiudi un'app un fulmine azzurro scende dalla cima dello schermo
  sulla sua icona del Dock, con un lampo e il tuono (se i suoni sono accesi). La posizione dell'icona si legge con
  l'Accessibilità; per le app che non tieni nel Dock (l'icona sparisce appena chiudi) si usa quella letta l'ultima volta
  che l'app è venuta davanti. Senza permesso o con Riduci movimento niente fulmine. Nessun dato esce dal Mac.

Non fatto: **neve sui widget della scrivania**. Sul Mac di prova non ci sono widget sulla scrivania, Stage Manager è
spento e lo schermo non ha la notch: non si può vedere come macOS elenca i widget (`CGWindowList`) né provare il resto.
Aggiungerli o accendere Stage Manager avrebbe cambiato il Mac condiviso. Per la notch il mucchio sta già sotto la barra
dei menu (`visibleFrame`), quindi sotto la notch non si posa niente.

Il codice: `Engine/Weather.swift` (`Wind`, `VideoGame`, `EffectGate`, `SeasonCalendar`), `Engine/Bolt.swift`,
`Sparks.splash`, `GlassDrops.splashes`, `Pile.melt`, `Sky.strikeNow`; gli avvisi del sistema in `AppDelegate`
(app davanti, app chiusa, Risparmio energetico, temperatura). I numeri in `Tuning.swift`, sezione «Secondo giro meteo».

## Pioggia, temporale, nebbia, nuvole (2.0)

- **Pioggia sul vetro.** Lo schermo è il vetro di una finestra: le gocce si posano a caso, quelle che si toccano
  si uniscono (le aree si sommano), e quando una è abbastanza grossa scorre giù, sempre più veloce quanto più è pesante,
  raccoglie le gocce che incontra e lascia dietro goccioline. Arrivata sul bordo scoperto di una finestra o sul Dock
  cade giù libera; in fondo allo schermo sparisce. Quando il vetro è pieno, la pioggia cade sulle gocce che ci sono.
- **Temporale.** Pioggia forte e obliqua (copre tutto lo schermo, anche il lato da cui viene), nuvole scure in cima,
  gocce sul vetro, e ogni 6–18 s un lampo lontano: due bagliori che illuminano le nuvole e il cielo dietro, poi,
  1,5–4 s dopo, il tuono (suono `tuono`).
- **Nebbia.** Tre strati bassi e sfumati, uno sopra l'altro, che scorrono verso destra a velocità diverse.
- **Nuvole.** Banchi bianchi che attraversano piano la parte alta dello schermo; usciti a destra rientrano da sinistra.
- L'intensità (menu e "Quantità") cambia quante gocce cadono sul vetro e quanti banchi ci sono.
- Con **Riduci movimento**: niente lampi (è luce che lampeggia), banchi al 40% della velocità e la metà dei banchi,
  metà delle gocce nuove, che scorrono a metà velocità e senza zigzag.
- Niente si posa sulle finestre: scegliendo una di queste stagioni la neve posata si scioglie.

Il codice: `Toys/Snowball/Snowball.swift` (palla, pupazzo, quando tre palle fanno un pupazzo), e in `SeasonScene`
le sezioni «Palle di neve e pupazzo» e «Palla di vetro». La neve che segue la finestra è `Pile.carry`.
Spazzaneve, montagnetta, slittino, funivia e albero sono in `Toys/WinterPlay/`, con i comandi del menu in `WinterPlay.swift`
(un'estensione di `SeasonScene`); i numeri in `Tuning.swift`, sezione «Spazzaneve, slittino, funivia, albero».
CPU misurata sul Mac (Release, 60 fps, 30 s alternati): con albero, slittino, funivia e spazzaneve circa il 7% in più
della sola neve (9,6% contro 9,0%).

## Natale (2.0)

- **Babbo Natale** con la slitta e due renne attraversa il cielo, poco sotto la barra dei menu. Dal 1° dicembre
  al 6 gennaio (le stesse date del Natale delle app iPhone) passa da solo quando nevica: la prima volta tra 20 s e 1 minuto
  dall'avvio, poi ogni 6–12 minuti. Si chiama anche dal menu («Fai passare Babbo Natale»), in qualunque giorno d'inverno:
  da lì ripassa da solo ogni 1½–4 minuti (`Tuning.santaLoopInterval`) finché cambi stagione o metti in pausa i giochi.
- **Più schermi** (`Passages`, `Engine/ScreenRoute.swift`): un solo passaggio alla volta, che attraversa tutti gli schermi
  nell'ordine di Impostazioni → Schermi: da sinistra a destra (o al contrario); gli schermi che si sovrappongono in
  orizzontale (uno sopra l'altro, anche non centrati) sono una colonna, attraversata dall'alto in basso. Esce da uno schermo ed entra nel vicino alla stessa quota globale; se il vicino non la copre (schermi sfalsati),
  vola alla quota solita di quello schermo. Con uno schermo solo è come prima.
- **Un regalo al giorno.** Babbo Natale lo lascia cadere su un bordo di finestra o sul Dock (senza, sul fondo): da solo
  un passaggio su due, dal menu sempre, finché oggi non l'ha lasciato. Il giorno si salva (`lastGiftDay` in UserDefaults),
  quindi uno al giorno anche riavviando l'app e con più schermi. Un clic lo apre: stelline, e salta fuori un omino di pan
  di zenzero. Aperto resta 3 s e poi sparisce.
- **Vigilia** (24/12): passa ogni 2–4 minuti e il primo passaggio porta sicuramente il regalo.
- **Omino di pan di zenzero** («Manda l'omino di pan di zenzero»). Parte dal bordo sinistro del Dock (senza Dock, dal fondo)
  e corre avanti e indietro sul suo bordo senza cadere. Se il cursore arriva a meno di 120 pt scappa più veloce; messo
  all'angolo salta oltre il cursore. Preso con un clic, sparisce tra le stelline. Al massimo 3.
- **Conto alla rovescia per Natale** (voce del menu, si ricorda al riavvio): un pannellino sulla scrivania, sopra le icone e
  sotto le finestre delle app, con giorni, ore e minuti alla mezzanotte del 25 dicembre; il giorno di Natale «Buon Natale!».
  Si sposta trascinandolo e ricorda dove l'hai messo. Si aggiorna una volta al minuto.
- Con **Riduci movimento** la slitta non attraversa lo schermo (il regalo cade dritto dove sarebbe arrivato), l'omino
  cammina piano, non salta e non dondola, le stelline non si allargano.
- Babbo Natale e l'omino sono solo d'inverno, come i giochi; cambiando stagione slitta, regali e omini spariscono.
  «Metti in pausa i giochi» ferma l'omino e toglie la slitta in volo.
- Suoni (se ci sono i file, SBU-56): `babbo-natale`, `regalo`, `omino`, `omino-preso`.

Il codice è in `Toys/Christmas/`: `Christmas.swift` (date, conto alla rovescia, `GiftDiary`, quando passa e se porta il regalo),
`ChristmasCast.swift` (Babbo Natale, regalo, omino e la sua corsa), `ChristmasVisits.swift` (l'estensione di `SeasonScene`
con il passo di Natale e i comandi), `Passages.swift` (quando passa e su quali schermi, uno per tutti gli schermi),
`CountdownPanel.swift`. I numeri in `Tuning.swift`, sezione «Natale».
CPU misurata sul Mac (Release, 60 fps, 30 s per giro, sullo stesso Mac carico di altri processi): con Babbo Natale chiamato
ogni 7,5 s, due omini che corrono e il conto alla rovescia acceso 17,3%, sola neve 17,4%: nessuna differenza misurabile.

## Personaggi e notte (2.0)

- **Personaggi** (menu ❄︎ → Personaggi, uno per tipo: la voce lo mette sullo schermo del cursore, la seconda volta lo toglie).
  Sono oggetti come gli altri: si trascinano, cadono e stanno sui bordi delle finestre, sul Dock o sul fondo.
  - **Volpe**: dorme acciambellata. Un clic la sveglia: annusa 2,5 s, cammina sul suo bordo senza cadere e dopo 12 s torna a dormire.
  - **Cincia e mangiatoia**: la mangiatoia è vuota. Un clic mette 6 semi, arriva la cincia e ne becca uno ogni 1,5 s; finiti, vola via.
  - **Baita**: un clic accende il fuoco (la finestra si scalda, dal camino esce il fumo), un altro lo spegne.
  - **Lanterna**: un clic la accende (fiamma e alone che tremolano), un altro la spegne.
  - **Renna**: parte sopra la finestra più in alto e ci cammina avanti e indietro. Col cursore a meno di 90 pt il naso
    si illumina, più forte quanto più è vicino. Un clic la fa girare.
- **Notte** (Impostazioni → Notte: Mai, Di sera, Sempre). Lo schermo si abbassa un po' (22%) dietro la neve e gli oggetti,
  e in basso a destra si accende una candela con l'alone e una luce calda sul fondo. «Di sera» va dall'ora scelta
  (18:00–2:00, 22:00 all'inizio) alle 6 del mattino. Si ricontrolla una volta al secondo e si accende sfumando in 2 s.
  C'è in tutte le stagioni.
- Con **Riduci movimento** la volpe non annusa, renna e volpe camminano a metà velocità e senza dondolare, la baita non fa
  fumo, la cincia sparisce invece di volare via, fiamme e candela non tremolano, la notte arriva senza sfumare.
- I personaggi sono solo d'inverno, come i giochi: cambiando stagione spariscono. «Metti in pausa i giochi» li ferma.
- Suoni (se ci sono i file, SBU-56): `volpe`, `cincia`, `baita`, `lanterna`, `renna`.
- Disegni nostri, forme semplici fatte in codice (`drawnTexture`): si possono sostituire con immagini senza cambiare la logica.

Il codice è in `Toys/Figures/`: `Figures.swift` (i cinque personaggi, `SeedTray`, `Pacing`) e `FigureVisits.swift`
(l'estensione di `SeasonScene` con i comandi e il passo); la notte è `Engine/Night.swift` (`NightClock` e la candela).
I numeri in `Tuning.swift`, sezione «Personaggi e notte».
CPU misurata sul Mac (Release, 60 fps, schermo 1920×1080, neve Media, tempo di CPU su 20 s, 4 giri alternati): con i cinque
personaggi e la notte accesa 7,7%, sola neve 7,6% (+1%).

## Menu ❄︎

In ordine: effetto, intensità, giochi, Natale, notte, sfondi, suoni, impostazioni (SBU-57). I testi valgono per tutte le stagioni.

- **Mostra l'effetto** (⌘S) · **Effetto** (le stagioni) · **Dietro le finestre** · **Togli quello che si è posato** (⌘R)
- **Intensità**: Leggera/Media/Forte con le scorciatoie, e sotto un cursore continuo
- **Giochi**: Togli le palle di neve · Scuoti la palla di vetro · Manda lo spazzaneve · Prima il Dock · Prepara la pista da slittino ·
  Monta/Togli la funivia · Pianta un albero di Natale · Togli alberi, neve e slitte · Metti in pausa i giochi ·
  Personaggi (Volpe, Cincia e mangiatoia, Baita, Lanterna, Renna)
- **Natale**: Fai passare Babbo Natale · Manda l'omino di pan di zenzero · Conto alla rovescia per Natale
- **Notte**: Mai · Di sera · Sempre (l'ora di inizio è nelle Impostazioni)
- **Sfondi…** · **Suoni** (acceso o spento; il volume è nelle Impostazioni)
- **Impostazioni…** (⌘,) · **Tour di benvenuto…** · Informazioni · Esci (⌘Q)

Il cursore dell'intensità è lo stesso valore di "Quantità" nelle Impostazioni: muovendolo le particelle in più nascono in cima
e quelle in meno spariscono, quelle che stanno cadendo non saltano.
Le scorciatoie funzionano a menu aperto: non sono globali.
L'effetto scelto si salva (la neve è quello di partenza) e l'icona nella barra dei menu lo segue.
I giochi d'inverno, Babbo Natale e l'omino sono spenti nelle altre stagioni.

**Tour di benvenuto.** Alla prima apertura (anche per chi aggiorna dalla 1.x) si apre il tour, sei pagine: benvenuto,
effetti, giochi, Natale, notte, sfondi. In fondo a ogni pagina ci sono due cose da provare, che si spuntano da sole
quando le fai: scegliere un altro effetto, scuotere il cursore (vale anche "Scuoti la palla di vetro", e anche con
Riduci movimento, dove la palla non si agita). Il tour si riapre dal menu; le spunte restano (`Tour/TourProgress.swift`).
Le volte dopo, aperta a mano, l'app mostra le Impostazioni come prima.

**Dietro le finestre.** La finestra degli effetti scende appena sopra lo sfondo e le icone della scrivania
(`OverlayWindow.level(behindWindows:)`): le app restano davanti, la neve si vede sulla scrivania e si posa lo stesso
sui bordi scoperti delle finestre. Si accende dal menu o dalle Impostazioni; la finestra lo legge a ogni fotogramma.

**CPU** (SBU-57, Release, neve Media, schermo 1920×1080, Mac a corrente carico di altri processi, tempo di CPU su 20 s,
3 giri alternati con `app/seasons-2`): base 15,1%, con menu e tour 13,3%. Nessuna differenza misurabile: il tour è
una finestra SwiftUI chiusa quasi sempre, e "Dietro le finestre" è un confronto di un Bool a fotogramma.

**Impostazioni**: effetto e dietro le finestre, meteo (meteo a caso, arcobaleno, mucchi più alti, 120 fps), quantità, dimensione e velocità delle particelle, vento, raggio e forza del cursore,
accumulo sulle finestre e sul fondo, velocità di accumulo, altezza massima, suoni e volume (spenti all'inizio), notte (mai, di sera dalle…, sempre),
apri al login, ripristino.
Le modifiche si vedono subito (nevica anche sulla finestra Impostazioni, utile per provare) e vengono salvate.

## Struttura

Il **motore** (`Engine/`) è comune a tutte le stagioni; ogni **stagione** (`Seasons/<Nome>/`) dice solo che cosa cade.

| File | Cosa fa |
|---|---|
| `App.swift` | Punto di ingresso, app senza icona nel Dock |
| `AppDelegate.swift` | Una finestra per schermo, menu ❄︎ e i suoi sottomenu, apre tour, Impostazioni e Sfondi, legge le finestre 8 volte al secondo |
| `Tour/` | Il tour di benvenuto: pagine (`TourPage`), cose da provare (`TourChallenge`), stato salvato (`TourProgress`), finestra (`TourView`) |
| `Engine/Season.swift` | Il protocollo `Season` e `Particle`: ciò che una stagione deve dire al motore |
| `Engine/OverlayWindow.swift` | Finestra trasparente, sempre sopra, attraversata dai click; il suo display link muove la scena |
| `Engine/SeasonScene.swift` | Fiocchi, vento, cursore, collisione coi mucchi, neve che cade quando muovi una finestra |
| `Engine/Pile.swift` | Un mucchio: altezze per colonna, frana, scavo col cursore, disegno |
| `Engine/Toy.swift`, `Engine/ToyBody.swift`, `Engine/Ledge.swift` | Gli oggetti con cui giocare: disegno, fisica (gravità, appoggio, lancio), i bordi su cui stanno |
| `Engine/ShakeDetector.swift`, `Engine/WindowShakes.swift`, `Engine/Shake.swift` | Cursore e finestre scossi |
| `Toys/Snowball/Snowball.swift` | Palla di neve (rotola), pupazzo, `snowmanTrio` |
| `Engine/Sky.swift` | Banchi a tutto schermo (nebbia, nuvole: pochi sprite grandi e sfumati) e lampi |
| `Engine/Weather.swift`, `Engine/Sparks.swift`, `Engine/Rainbow.swift` | Meteo a caso, cursore fermo, schermo coperto; scintille delle stelle; arcobaleno (SBU-177); vento, videogiochi, quando gira l'effetto, segui la stagione; schizzi (SBU-185) |
| `Engine/Bolt.swift` | Il fulmine sull'icona del Dock di un'app chiusa mentre piove (SBU-185) |
| `Engine/Glass.swift` | Gocce sul vetro: `GlassDrops` (logica, testata) e `Glass` (una sprite per goccia) |
| `Toys/Christmas/` | Babbo Natale, il regalo, l'omino di pan di zenzero, il conto alla rovescia e le date di Natale |
| `Toys/Figures/` | I personaggi: volpe, cincia con la mangiatoia, baita, lanterna, renna e i loro comandi (`FigureVisits.swift`) |
| `Engine/Night.swift` | La notte: quando è notte (`NightClock`), lo schermo più scuro e la candela |
| `Toys/WinterPlay/` | Spazzaneve, montagnetta, slittino, funivia, albero di Natale e i loro comandi (`WinterPlay.swift`) |
| `Engine/SoundBoard.swift` | Effetti brevi e sottofondo in loop (`AVAudioPlayer`) |
| `Engine/Windows.swift` | Dove sono le finestre (`CGWindowListCopyWindowInfo`) e quali tratti dei bordi sono scoperti |
| `Seasons/Seasons.swift` | L'elenco delle stagioni, una riga ciascuna |
| `Seasons/Snow/Snow.swift` | La neve: forma, colore e caduta dei fiocchi (`SnowTuning`) |
| `Seasons/Summer/Summer.swift` | L'estate: semi di tarassaco, lenti e larghi nell'ondeggiare, si posano color panna (`SummerTuning`) |
| `Seasons/Spring/Spring.swift`, `Seasons/Autumn/Autumn.swift` | Petali di ciliegio portati dal vento e foglie d'autunno che volteggiano e si posano |
| `Seasons/Fireflies/Fireflies.swift` | Le lucciole: luci che vagano piano e si accendono e si spengono, non si posano (`FirefliesTuning`) |
| `Seasons/Meteors/Meteors.swift` | Le stelle cadenti: ogni tanto una scia attraversa il cielo di traverso (`MeteorsTuning`) |
| `Seasons/Rain/Rain.swift`, `Seasons/Storm/Storm.swift` | Pioggia sul vetro; temporale: pioggia obliqua, nuvole scure, lampi |
| `Seasons/Mist/Mist.swift`, `Seasons/Clouds/Clouds.swift` | Nebbia in strati bassi; nuvole in alto |
| `Seasons/Clear/Clear.swift` | Il sereno: non cade niente (per chi vuole solo gli oggetti o lo sfondo) |
| `PowerSource.swift` | Batteria o corrente (per i fotogrammi al secondo) |
| `Settings.swift` | Le impostazioni e la stagione (salvate in UserDefaults) e la finestra SwiftUI per regolarle |
| `Localizable.xcstrings`, `InfoPlist.xcstrings` | Le stringhe in italiano e inglese; il nome "Sbu Seasons" nel menu dell'app in alto |
| `Density.swift` | Le scorciatoie Leggera / Media / Forte del menu |
| `Tuning.swift` | I parametri fissi del motore (fisica, cursore, mucchi, lettura delle finestre) e i momenti del giorno |
| `Gallery/` | La finestra Sfondi, i dieci sfondi (`Wallpaper`), lo sfondo di prima (`WallpaperMemory`), le anteprime |
| `DayCycle/` | Momenti del giorno (`DayMoment`, `MomentLook`, `DayTint`), la scelta (`MomentChoice`, `WallpaperPrefs`), chi cambia gli sfondi (`WallpaperDirector`) |
| `Saver/` | Il salvaschermo, parte comune ad app e `.saver`: opzioni, scena, installazione |
| `../SaverBundle/` | Solo nel `.saver`: la `ScreenSaverView`, le opzioni in Impostazioni di Sistema |
| `WhatsNew/` | «Novità»: le righe di ogni versione (`WhatsNew`) e la schedina nel menu (`WhatsNewCard`) |
| `project.yml` | Progetto XcodeGen: target app (LSUIElement), salvaschermo (`SbuSeasonsSaver`) e test |

I valori predefiniti sono in `SnowSettings` (`Settings.swift`); i parametri fissi in `Tuning.swift`.

## Clic sugli oggetti

La finestra della neve copre tutto lo schermo e sta sopra alle altre, ma i clic la attraversano
(`ignoresMouseEvents = true`): il Mac si usa come se non ci fosse. Per cliccare e trascinare un oggetto,
la finestra deve prendere il mouse **solo** sopra l'oggetto.

Come: a ogni fotogramma la scena legge già dove è il cursore (serve ai fiocchi). Con quella posizione guarda
se sotto c'è un oggetto, o se ne stai trascinando uno (`SeasonScene.wantsMouse`). Solo allora la finestra mette
`ignoresMouseEvents = false`; appena il cursore esce torna `true`. Il valore si cambia solo quando cambia: leggere
`ignoresMouseEvents` a ogni fotogramma costava CPU.

Perché così e non un monitor globale degli eventi (`NSEvent.addGlobalMonitorForEvents`): un monitor globale vede i clic
ma non li può fermare, quindi il clic arriverebbe anche all'app sotto l'oggetto; per fermarli servirebbe un event tap,
che chiede il permesso "Monitoraggio input". Così invece non serve nessun permesso e il clic va solo a uno dei due.

Dettagli:
- la finestra è un `NSPanel` "non attivante": cliccare un oggetto non porta Sbu Seasons davanti e non toglie la tastiera
  all'app che usi; la `SKView` accetta il primo clic (`acceptsFirstMouse`), se no il primo clic andrebbe perso;
- clic = pressione e rilascio a meno di 4 pt (`Tuning.clickSlop`): l'oggetto riceve `clicked()`; più lontano è un
  trascinamento, e al rilascio l'oggetto parte con la velocità del mouse (fermo da più di 0,1 s: cade dritto);
- limite: tra un fotogramma e l'altro (16 ms) il cursore può arrivare sull'oggetto e cliccare prima che la finestra
  prenda il mouse; in quel caso il clic va all'app sotto. Con un movimento normale non succede.

Provato sul Mac: il clic sull'oggetto arriva all'oggetto e l'app davanti resta davanti; il clic fuori dall'oggetto
arriva alla finestra sotto; il trascinamento e il lancio funzionano.

## Aggiungere un oggetto

1. Una sottoclasse di `Toy` nella cartella della sua funzione (per esempio `Toys/Snowball/`), con il suo `SKSpriteNode`
   (l'àncora è il centro in basso: `position` è dove poggiano i piedi).
2. Sovrascrivi quello che serve: `clicked()` (clic), `clicked(at:)` (clic con il punto rispetto ai piedi, per l'albero), `shaken(_:)` (`.pointer` o `.window(id)` scossi), `bounce`.
3. Aggiungilo con `SeasonScene.add(_:)` (dall'app: `OverlayWindow.add(_:)`). Il motore lo fa cadere e lo posa sui
   tratti scoperti dei bordi delle finestre, sul Dock o sul fondo dello schermo; se la finestra si sposta o si chiude, cade.
   Dove coprirebbe la barra dei menu (un oggetto più alto della neve, su una finestra vicina alla barra) non si ferma e cade più giù.
4. I suoni: `SoundBoard.shared.play("nome")` per un effetto, `startAmbience("nome")` per il sottofondo.
   Il file `nome.caf` (o `.m4a`, `.wav`, `.aiff`, `.mp3`) va in `SbuSeasons/`; se manca, non suona e non succede niente.

Scuotere: il cursore va avanti e indietro 4 volte in 1 s, di almeno 40 pt (`ShakeDetector`); una finestra 3 volte
in 1,5 s (le finestre si leggono solo 8 volte al secondo). Chi continua a scuotere fa una scossa sola.

## Aggiungere una stagione

1. Crea la cartella `SbuSeasons/Seasons/<Nome>/` con un file `<Nome>.swift` e un tipo che segue `Season`
   (copia `Snow.swift` come punto di partenza):
   - `id`: una parola in inglese minuscolo (`"leaves"`); si salva nelle impostazioni, quindi una volta uscita non cambia;
   - `title`: il nome nel menu, con `String(localized:)`, e la traduzione inglese in `Localizable.xcstrings`;
   - `symbol`: il simbolo SF per la barra dei menu e per il menu Effetto;
   - `pileColor`: il colore di ciò che si posa sulle finestre e sul Dock;
   - `makeTexture()`: la forma della particella, disegnata una volta;
   - `particle(depth:)`: raggio, opacità, velocità di caduta e oscillazione di una particella (0 = lontana, 1 = vicina);
     se serve anche rotazione (`spin`, `flip`), colore (`tint`), andare di traverso orientata (`drift`, `length`),
     vagare in su e in giù (`bob`), accendersi e spegnersi (`pulse`), aspettare prima di ripassare (`gap`);
   - se non deve posarsi: `settles = false` (scegliendola, la neve posata si scioglie); se ne servono meno o nessuna:
     `abundance` (× "Quantità": 0,12 le lucciole, 0,01 le stelle, 0 il sereno);
   - se servono: `banks` (strati di nebbia o nuvole che scorrono, `Bank`), `lightning` (lampi, `Lightning`),
     `glass` (gocce sul vetro, `GlassRain`). Qualunque stagione li può usare, anche insieme alle particelle.
2. Aggiungi una riga in `Seasons/Seasons.swift`, nell'ordine in cui la vuoi nel menu. Nient'altro da toccare nel codice.
   Attenzione: alcuni testi parlano ancora solo di neve («Fai nevicare», «Sciogli la neve», le sezioni «Nevicata»
   e «Neve posata» e «Quantità di fiocchi» nelle Impostazioni). Renderli generici è una decisione di Matteo,
   da prendere prima che esca la seconda stagione.
3. I colori e i numeri della stagione stanno nel suo file (un `enum <Nome>Tuning` come `SnowTuning`), non in
   `Design/tokens.json`: sono contenuto, non interfaccia, e li approva Matteo guardando lo screenshot.
4. `xcodegen`, poi `xcodebuild test -scheme SbuSeasons -destination 'platform=macOS'`, e misura la CPU con la neve
   come riferimento: una stagione non deve consumare di più.

**CPU** (SBU-51, MacBook a corrente, intensità Media, media di 15 s con `ps`): neve 6,2%, autunno 6,6%, primavera 7–8%,
lucciole 5,1%, stelle cadenti 4,4%, sereno 1,7%. Il motore nuovo non cambia la neve (5,9–6,7% prima, 5,5–6,3% dopo).

**CPU della 2.0 meteo** (SBU-52, Mac a corrente, schermo 1920×1080, intensità Media, tempo di CPU su 20 s, media di 4 giri
alternati con la neve): neve 9,1%, temporale 9,5% (+4%), pioggia sul vetro 8,7%, nebbia 6,0%, nuvole 5,5%.
Le misure dello stesso effetto variano di ±1,5 punti da un giro all'altro: per confrontare, alterna sempre con la neve.

Se a una stagione serve qualcosa che il motore non sa fare (farle rimbalzare…),
si cambia `Season` e `SeasonScene` in un lavoro a parte, prima, perché tocca tutte le stagioni.

## Prossimi passi possibili

- Alba e tramonto veri dalla stagione (oggi le ore dei momenti sono fisse, `Tuning.momentStarts`)

## Sfondi e suoni (2.0)

- **Sfondi** (menu ❄︎ → «Sfondi…»). Dieci scene (`Wallpapers/`, fatte per noi in SBU-67), ognuna in 16:10 e in 21:9:
  gli schermi con rapporto da 2 in su (ultrawide) prendono la versione larga. Si sceglie lo schermo (con più monitor),
  la scena e «Imposta sfondo». Con «Anche l'effetto consigliato» acceso cambia anche la stagione (baita → stelle cadenti,
  pioggia di marzo → pioggia sul vetro…). Il file si copia in `~/Library/Application Support/Sbu Seasons/Wallpapers`:
  macOS ricorda il percorso, e così lo sfondo resta anche se l'app si sposta o si aggiorna.
- **«Lascia il mio schermo com'è»** rimette lo sfondo che c'era prima di usare la galleria, schermo per schermo
  (`WallpaperMemory`, per nome dello schermo; si ricorda solo il primo, non i nostri).
- **Suoni** (spenti di default, Impostazioni → Suoni). File in `Sounds/`; più file numerati (`pallina-1`, `-2`, `-3`)
  sono lo stesso effetto e ne suona uno a caso.

  | Momento | Suono |
  |---|---|
  | Nasce una palla di neve | `passo-neve` (scricchiolio) |
  | Lanci una palla | `palla-di-neve-lancio` |
  | Una palla arriva forte su un bordo | `palla-di-neve-colpo` |
  | Pupazzo, palla di vetro, spazzaneve, slittino, funivia | `pupazzo`, `palla-di-vetro`, `spazzaneve`, `slittino`, `funivia` |
  | Pallina sull'albero | `pallina` (tre note) |
  | Babbo Natale, regalo, omino | `babbo-natale`, `regalo`, `omino` |
  | Tuono dopo il lampo | `tuono` |
  | Baita accesa, lanterna | `camino`, `lanterna` |
  | Sottofondo: neve / pioggia e temporale | `vento` / `pioggia` (in loop, solo mentre cade qualcosa) |

  Senza file restano muti l'omino preso, la volpe, la cincia e la renna.
- Il codice: `Gallery/` (galleria) ed `Engine/SoundBoard.swift`; il sottofondo di una stagione è `Season.ambience`.

## Sfondi per ora del giorno e salvaschermo (2.1)

Come Koi Art, ma tutto sul Mac: nessuno sfondo scaricato, nessun controllo aggiornamenti, nessun dato che esce (SBU-179).

- **Ora del giorno** (Impostazioni → Sfondi, o nella finestra Sfondi). Otto momenti fatti a codice con Core Image dal disegno
  che c'è, senza immagini nuove (`DayTint`: luce, temperatura, colore e un velo di cielo che sfuma dall'alto; i valori sono
  in `Tuning.momentLooks`). Uno sfondo già scuro (la sera di luglio) si scurisce meno, se no di notte diventa nero.
  Mezzogiorno è il disegno com'è. I momenti cominciano a ore fisse dell'ora del Mac (`Tuning.momentStarts`: alba alle 5,
  aurora 6:30, mattina 8, mezzogiorno 11, ora d'oro 16, tramonto 18, crepuscolo 19:30, notte 21): niente posizione, niente rete.
  «Segue l'ora del Mac» mette uno **sfondo dinamico di macOS** (SBU-189): un solo HEIC con gli otto momenti e, nei metadati
  XMP del primo fotogramma, l'ora a cui comincia ognuno (`apple_desktop:h24`, lo stesso formato degli sfondi dinamici di
  Apple; `DynamicWallpaper`). Il cambio lo fa macOS, anche ad app chiusa: nessun timer e nessuna CPU dell'app. Il file si fa
  una volta per sfondo e formato, in circa 0,7 s, e pesa 5–9 MB (`01-prima-neve-16x10-giorno-e-notte.heic`). Le ore sono
  ore locali: viaggiando con un altro fuso, il cambio segue l'ora del Mac. macOS non cambia al minuto esatto: può arrivare
  qualche minuto dopo l'ora del momento. Il vecchio controllo al minuto resta solo di ripiego, se l'HEIC non si riesce a
  scrivere (allora si mette il JPEG del momento). Un momento fisso è un JPEG (`01-prima-neve-16x10-night.jpg`), e lì un
  timer non serve. Tutto resta in `Application Support/Sbu Seasons/Wallpapers`; il lavoro pesante è fuori dal main thread.
- **Lo sfondo torna se macOS lo perde** (SBU-189): al risveglio dallo stop o cambiando schermi, se su uno schermo c'era uno
  dei nostri e adesso c'è uno sfondo di sistema (`/System/Library/Wallpapers`, `Desktop Pictures`) o nessuno, si rimette
  (`Wallpaper.wasLost`). Una tua foto non si tocca mai. Limite noto: se scegli proprio uno sfondo di sistema al posto del
  nostro, al cambio di schermo seguente torna il nostro. Serve l'app aperta.
- Lo sfondo cambia solo sugli schermi dove c'è ancora uno dei nostri: se metti una tua foto, resta la tua.
  «Lascia il mio schermo com'è» rimette la tua e smette di cambiarlo.
- **Tutti gli schermi** con un clic: nella finestra Sfondi, con più monitor, «Schermo» → «Tutti gli schermi».
- **Lo sfondo segue l'effetto** (Impostazioni → Sfondi): cambiando effetto, dal menu, dalle Impostazioni o dal meteo a caso,
  su tutti gli schermi arriva lo sfondo consigliato (`Wallpaper.suggested`). Se lo sfondo di adesso va già bene con l'effetto
  (le due scene con la neve) resta quello; se nessuno sfondo consiglia l'effetto (estate, sereno) non cambia niente.
- **Salvaschermo** (`SbuSeasonsSaver`, `Sbu Seasons.saver` dentro l'app in `Contents/Resources`). Uno sfondo del borgo nel
  momento del giorno e sopra il suo effetto (la stessa `SeasonScene` della scrivania, che cade fino in fondo). Opzioni in
  Impostazioni di Sistema: lo sfondo scelto oppure uno diverso ogni volta, l'effetto sopra sì o no. A batteria va a 30
  fotogrammi; con Riduci movimento anche con metà particelle e senza vento. Impostazioni → Sfondi → «Installa…» lo copia in
  `~/Library/Screen Savers` e apre Impostazioni di Sistema (da macOS 15 in Sfondo → «Salvaschermo…»): lo scegli tu, l'app
  non lo attiva e non lo avvia mai. Il salvaschermo gira dentro un processo di macOS e non legge le impostazioni dell'app:
  le sue opzioni sono a parte (`ScreenSaverDefaults`). Pesa 28 MB perché porta con sé i suoi sfondi.
- **Novità** (`WhatsNew/`): dopo un aggiornamento, la prima volta che apri il menu ❄︎, una schedina in cima con le righe
  della versione (`WhatsNew.notes`). Si chiude con la ✕ o chiudendo il menu e non torna. Alla prima installazione no:
  c'è il tour. Le correzioni (2.1.1) non hanno una schedina loro. Per una versione nuova si aggiunge una voce a `notes`.
