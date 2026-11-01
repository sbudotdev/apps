# Sbu ZTL usa i servizi di Apple e un grafo OSM nel bundle

Mappa, ricerca dei luoghi e percorso fuori dalle città coperte usano MapKit, quindi parlano con Apple: è un'eccezione a "nessuna chiamata di rete", accettata perché un navigatore non esiste senza mappa e Apple è già sul telefono. Nessun server Sbu, nessun SDK di terzi, nessun account. Regole e perimetri stanno nel bundle e si aggiornano con le versioni dell'app; una regola non verificata risponde "non lo so".

Dentro le città coperte il percorso viene da un grafo OSM nel bundle con A* in Swift: le prove con il solo `MKDirections` restano sotto soglia (7/10 contro 9/10). Il grafo è un database derivato da OSM: ODbL, file separato, attribuzione visibile in Impostazioni. La lettura legale resta da confermare (#630) prima dell'invio. I dati del veicolo si compilano a mano: una ricerca per targa richiederebbe un servizio esterno.
