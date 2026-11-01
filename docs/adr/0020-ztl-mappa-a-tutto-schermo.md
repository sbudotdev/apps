# Sbu ZTL è una mappa a tutto schermo, con la stessa esperienza dell'originale

Matteo vuole la stessa esperienza d'uso di ZigZag: mappa a tutto schermo con orario e veicolo in alto, pannello in basso, guida svolta per svolta. La schermata principale quindi non ha `SbuScreenTitle`, griglia né `SbuFigure`: non c'è una cifra sola da mostrare, e la griglia starebbe sopra contenuto reale.

Eccezioni al design system, solo qui: i colori di stato riempiono le zone sulla mappa, perché è lì che si legge la risposta, sempre con la parola e il simbolo nel pannello; il primo avvio resta `SbuEmpty` senza carosello, seguito dal giro guidato sulla mappa. Testi, grafica e colori restano Sbu (ADR-0003). Niente paywall: tutte le funzioni sono gratis.

Vale anche per anteprima e guida: una figura da 144 pt nel pannello copre la mappa, che è ciò che in quel momento serve vedere (provato il 1/11). Tempo e distanza restano testo. La figura sta nell'elenco delle ZTL, che ha titolo e carta.
