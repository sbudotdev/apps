# Video di Natale: lista riprese per Matteo

v1 · 17 novembre 2026 · SBU-36. Va con `copione.md`. Tempo totale: circa 30 minuti.

## Quando si può girare

- **R1 e R4** (tu in camera e la voce): quando vuoi, anche subito.
- **R2 e R3** (lo schermo dell'app): solo quando sul telefono c'è la build di Sbu Subscriptions con il riepilogo (SBU-34, PR prevista entro il 2/12), installata da Xcode o da TestFlight interno, e **dal 1/12**, perché il tema di Natale e il riepilogo si accendono da soli in base alla data.

## Prima di iniziare

1. Modalità Non disturbare attiva, così nessuna notifica entra nell'inquadratura.
2. Batteria sopra il 50% (l'icona della batteria scarica si nota) e Wi-Fi acceso: la barra di stato resta pulita.
3. Fotocamera: Impostazioni > Fotocamera > Registra video > **4K a 30 fps**.
4. Dati nell'app: **dati di esempio** (consigliato), così non mostri le tue spese. Da Xcode: schema SbuSubscriptions, argomento di avvio `-FASTLANE_SNAPSHOT YES`. Se preferisci usare i tuoi abbonamenti veri, controlla prima che non ci sia niente che non vuoi far vedere.

## Le riprese, in ordine

| # | Cosa | Come | Durata da girare | Usata nel video |
|---|---|---|---|---|
| R1 | Tu in camera: le battute da "John mi fa" a "Per tenere d'occhio gli abbonamenti" | Telefono in verticale, all'altezza degli occhi (su un treppiede o appoggiato ai libri), fotocamera **posteriore** (qualità migliore; controlla l'inquadratura con una prova prima), oppure la frontale se giri da solo senza treppiede. Luce di una finestra davanti a te, mai alle spalle. Mezzo busto, sguardo nell'obiettivo. Parla al telefono come se raccontassi la cosa a un amico. **La voce si registra qui, in presa diretta**: stanza piccola, porta chiusa, telefono a non più di un metro | 15-20 s per ripresa, **3 ripetizioni** di fila | 0-11,5 s |
| R2 | Schermo: apri Sbu Subscriptions e mostra la lista con la cifra in alto | Centro di Controllo > Registrazione schermo, **microfono spento**. Parti dalla Home: 1 s fermo, tocchi l'icona, l'app si apre, scorri piano la lista e torni su. Gesti lenti, niente tocchi a vuoto | 12 s, 2 ripetizioni | 11,5-20 s |
| R3 | Schermo: il riepilogo "Il tuo 2026 in abbonamenti" | Stessa registrazione schermo. Dalla lista tocchi il riepilogo, aspetti 2 s, scorri piano fino agli abbonamenti che si rinnovano a gennaio, fermo 2 s | 12 s, 2 ripetizioni | 20-27 s |
| R4 | Voce fuori campo: le battute da "Allora l'ho rifatta" a "Link in bio" | App Memo Vocali. Stessa stanza di R1, telefono a 15-20 cm dalla bocca, leggermente di lato (non ci soffi dentro). Leggi tutte le battute una dopo l'altra con un secondo di pausa tra una e l'altra | Circa 20 s per ripresa, **3 ripetizioni** | 11,5-33 s |

La chiusura (logo e URL) la faccio io al montaggio: non serve girarla.

## Le battute da leggere

R1, in camera:
> John mi fa: ho visto su Instagram il video di un'app fighissima. Ti dice quanto spendi in abbonamenti. Sarà gratis, figurati, è una cavolata farla. E invece no: per averla tutta paghi 22,99 euro l'anno. (pausa) Un abbonamento. Per tenere d'occhio gli abbonamenti.

R4, voce fuori campo:
> Allora l'ho rifatta. Si chiama Sbu Subscriptions. (pausa) Metti i tuoi abbonamenti e in alto vedi una cifra sola: quanto spendi all'anno. (pausa) E a dicembre ti fa il conto del tuo 2026, con quello che si rinnova a gennaio. (pausa) Gratis, niente account, niente pubblicità. Link in bio.

Il tono è quello di una chiacchierata, non di una pubblicità. Se una parola ti viene storta, ripeti la frase intera: taglio io.

## Come mandarmi i file

AirDrop sul Mac, tutti nella cartella `~/Desktop/natale-2026-riprese/`, senza rinominarli (le ripetizioni le riconosco dall'ordine). Poi un commento su SBU-36 con "riprese pronte". I file grezzi non vanno su git.
