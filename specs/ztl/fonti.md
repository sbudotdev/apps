# ZTL: fonti dati e licenze

Ricerca del 1/11/2026. **Non è consulenza legale.** Nessun dato è stato preso da ZigZag, dal suo sito o da altre app ZTL.

**Risposta breve:** sì, una app gratuita può includere i perimetri di 11 comuni, perché hanno una licenza aperta dichiarata. I varchi con coordinate o in dataset riusabile ci sono in 6 di questi (Bergamo, Bologna, Firenze, Milano, Roma, Torino). Attribuzione obbligatoria dove la licenza la prevede. Gli orari quasi ovunque vanno trascritti dagli atti, e diversi dataset sono vecchi: la licenza è a posto, l'aggiornamento no.

## Limiti di questa ricerca

- Le licenze provengono da pagine dataset o metadati API, lette tramite strumento di estrazione. Prima di includere un dataset, ricontrollare a occhio la pagina e la licenza del singolo file.
- Non ho scaricato i file geografici. L'unico contenuto letto è l'XML di Torino. Quindi la correttezza geometrica non è verificata in nessun comune.
- Budget superato: 39 letture di pagina (6 fallite), circa 18 chiamate API, 36 controlli di stato. I controlli di stato hanno usato uno user agent da browser.
- **Controllo superficiale:** Bari, Catania, Messina, Taranto, Parma, Venezia, Brescia, Villadossola, Cuorgnè. "Non trovato" qui vuol dire che non l'ho trovato, non che non esista.
- Un `package_search` CKAN con 0 risultati vale solo per quel portale e quella parola chiave.

Legenda dei link:

- **[L]** contenuto letto
- **[M]** metadati letti via API
- **[S]** aperta, verificati solo stato HTTP 200 e titolo (o tipo file)
- **[R]** vista solo nei risultati di ricerca, non aperta
- **[X]** apertura fallita

## Tabella per comune

| Comune | Perimetro: fonte | Formato e data | Licenza come scritta | Varchi | Regole e orari | Stato | Confidenza |
|---|---|---|---|---|---|---|---|
| Bari | Non trovata. CKAN `q=ztl` su [opendata.comune.bari.it](https://opendata.comune.bari.it/api/3/action/package_search?q=ztl): 0 risultati [M] | Non trovato | Non verificata | Nessun dataset; 7 varchi citati dalla Polizia Locale [R] | [Polizia Locale](https://www.poliziamunicipalebari.it/home-page/cosa-fare-in-caso-di/rilascio-permessi-ztl/) [X: host non risolto] | da chiedere al Comune | Bassa |
| Bergamo | [Zone ZTL, dati.lombardia](https://www.dati.lombardia.it/Mobilit-e-trasporti/Comune-Bergamo-Zone-a-Traffico-Limitato-ZTL-/tkwz-spd9/about_data) [M] | GeoJSON, CSV; 27 righe con `PERIODO`, `DETTAGLI`; dati 10/2024 | "Italian Open Data License 2.0" | Sì: [Varchi ZTL](https://www.dati.lombardia.it/Mobilit-e-trasporti/Comune-Bergamo-Varchi-ZTL/wmcb-3jfi) [M], "Creative Commons 1.0 Universal (Public Domain Dedication)", **dati 9/2016** | [Quali sono le ZTL](https://www.comune.bergamo.it/page:c_a794:zona.traffico.limitata;quali.sono.ztl) [S] | riusabile | Alta sulla licenza; media sui varchi (vecchi) |
| Bologna | [ZTL](https://opendata.comune.bologna.it/explore/dataset/zona-a-traffico-limitato/) [L], [API](https://opendata.comune.bologna.it/api/explore/v2.1/catalog/datasets/zona-a-traffico-limitato) [M] | Poligoni, 14 record, export OpenDataSoft; **agg. 8/2021** | "CC BY 4.0" (solo nei metadati API, la pagina non la mostra) | Sì: [79 varchi con coordinate](https://opendata.comune.bologna.it/api/explore/v2.1/catalog/datasets/varchi-bologna) [M], "CC BY 4.0", agg. 12/2024 | Solo la descrizione del dataset: 7-20, Zona T 24 h. Pagina comunale non trovata | riusabile | Alta sulla licenza; media sull'attualità |
| Brescia | Non trovata come dato. [Portale](https://dati.comune.brescia.it/) [S], nessuna ZTL in home | Mappa e planimetria varchi PDF (2/2024) [R] | Non verificata | Solo planimetria PDF ed elenco [R] | [Disciplina e mappa](https://www.comune.brescia.it/aree-tematiche/mobilita-e-trasporti/permessi-ztl/disciplina-e-mappa-ztl) [X: HTTP 410], [ZTL](https://www.comune.brescia.it/it/topics/ztl) [R] | solo da ridisegnare da fonte ufficiale | Bassa |
| Catania | Non trovata come dato. Elenco vie solo da siti terzi, non usati | Non trovato | Non verificata | Non verificato | [Disposizioni operative Comune/AMTS](https://www.amts.ct.it/wp-content/uploads/Sostare/Disposizioni_%20operative_%20accesso_alle_ZTL_e_%20AP.pdf) [S, PDF] | da chiedere al Comune | Bassa |
| Cesena | [Zone Traffico Limitato](https://dati.unionevallesavio.it/dataset/od-ztl-sdo) [M] (la pagina dà errore di certificato, l'API risponde) | WMS, WFS, SHP, CSV, OData; EPSG:25832; 1/2026 | "Creative Commons Attribuzione 4.0 Internazionale (CC BY 4.0)" | Non nel dataset; il Comune cita varchi nuovi dal 29/6 [S] | [Notizia varchi](https://www.comune.cesena.fc.it/novita/zona-a-traffico-limitato-da-lunedi-29-giugno-entrano-in-funzione-dieci-nuovi-varchi-elettronici/) [S] | riusabile | Alta sul perimetro; varchi assenti |
| Cuorgnè | Non trovata | Non trovato | Non verificata | Non verificato | Solo [regolamento videosorveglianza](https://www.comune.cuorgne.to.it/it-it/download/regolamento-gestione-sistema-videosorveglianza-pdf-19096-5-993-3b21d6aba731eb7dc9d2281a8468be57) [S, PDF], menziona varchi ZTL in generale [R]. ZTL attiva non confermata | non trovato | Bassa |
| Ferrara | [ZTL esistente](https://dati.comune.fe.it/dataset/ztl-esistente) [L] | WMS, WFS, SHP; 3/2025 | "Creative Commons Attribuzione 4.0 Internazionale (CC BY 4.0)" | Non verificato (non citati in pagina) | Pagina comunale non trovata | riusabile | Alta sul perimetro; varchi e orari aperti |
| Firenze | [Diurna](https://opendata.comune.fi.it/page_dataset_show?id=9257a75e-3af3-4845-b37d-1540be29115a) [L], [notturna](https://opendata.comune.fi.it/page_dataset_show?id=3d586fa5-7367-42c5-b5f2-d8348a5da431) [L]. Il [record INSPIRE](https://inspire-geoportal.ec.europa.eu/srv/api/records/c_d612:3d586fa5-7367-42c5-b5f2-d8348a5da431:1) [X: certificato scaduto] è lo stesso dataset | WMS, SHP, GeoJSON; 3/2026 | "Creative Commons Attribuzione 4.0 Internazionale (CC-BY 4.0)" | Sì: [Porte telematiche](https://dati.toscana.it/dataset/0fe68709-c864-4e21-b18e-07ee3e9328e2) [M], `cc-by-4.0`, SHP, GeoJSON; [Varchi Scudo Verde](https://opendata.comune.fi.it/content/varchi-scudi-verde) [S], licenza CC BY 4.0 nell'HTML | [Mobilità](https://mobilita.comune.fi.it/muoversi/muoversi/ztl.html) [L]; riporta ancora date 2022 | riusabile | Alta |
| Genova | [Zone a traffico limitato](https://dati.comune.genova.it/en/dataset/zone-a-traffico-limitato/resource/4243f13a-d325-40d4-bfcc-db474035bbb1) [L]; [WMS del Comune](https://mappe.comune.genova.it/geoserver/SITGEO/V_MOB_ZTL/wms?request=GetCapabilities&service=WMS) [S], senza licenza | SHP in Gauss-Boaga, **3/2018** | "Creative Commons Attribution 4.0 International (CC BY 4.0)". WMS: solo `AccessConstraints NONE`, che non è una licenza | Non verificato (va aperto lo ZIP) | [Disciplinare rev. 16/4/2025](https://www.comune.genova.it/sites/default/files/2025-06/Disciplinare%20ZTL%20aggiornato%20da%20DGC%2074-2025.pdf) [S, PDF] | riusabile | Alta sulla licenza; bassa sull'attualità (SHP di 8 anni fa) |
| Messina | Non trovata | Non trovato | Non verificata | Non verificato | [Notizia Comune](https://www.comune.messina.it/index.php/it/news/atm-lancia-gli-abbonamenti-mensili-nelle-ztl) [S], [ATM](https://www.atmmessinaspa.it/ztl.php) [S]. Dai risultati sembrano ZTL di sosta a pagamento [R] | da chiedere al Comune | Bassa |
| Milano | [Aree pedonali e ZTL](https://dati.comune.milano.it/dataset/ds51_trafficotrasporti_aree_pedonali_ztl) [L], include Area C e B | GeoJSON, SHP, CSV; 5/2026 | "Creative Commons Attribution" | Sì: [Area C](https://dati.comune.milano.it/dataset/ds82_infogeo_varchi_elettronici_localizzazione_) [L], 10/2026; [Area B](https://dati.comune.milano.it/dataset/ds959-varchi-areab) [L], 5/2026; stessa licenza | [Orari Area C](https://servizicrm.comune.milano.it/centro-supporto/KA-01151/Orari-di-attivazione-Area-C) [X: HTTP 403] | riusabile | Alta |
| Modena | [ZTL](https://opendata.comune.modena.it/it/dataset/ztl) [L] | WMS, WFS, SHP; 2/2023 | "Creative Commons Attribuzione 4.0 Internazionale (CC BY 4.0)" | Non nel dataset (da verificare in WFS/SHP); [mappa interattiva varchi](https://www.comune.modena.it/argomenti/ztl/mappa-dei-varchi-elettronici) [S], licenza non verificata | [Testo coordinato ordinanza](https://www.comune.modena.it/documenti-e-dati/atti-normativi/ordinanze/ordinanze-a-carattere-generale/testo-coordinato-ordinanza-ztl/testo-coordinato-ordinanza-ztl/@@download/file_principale) [R] | riusabile | Alta sul perimetro; varchi da ridisegnare |
| Napoli | Solo pagine web con elenco vie: [Centro Antico](https://www.comune.napoli.it/articolo_tematico/trasporti-mobilita/ztl-e-aree-pedonali/ztl-del-centro-antico/) [S] | Solo pagina web | Non verificata | Elenco nel testo, senza coordinate [R] | [Tarsia, Pignasecca, Dante](https://www.comune.napoli.it/articolo_tematico/trasporti-mobilita/ztl-e-aree-pedonali/ztl-tarsia-pignasecca-dante/) [S] | solo da ridisegnare da fonte ufficiale | Media |
| Padova | PDF "Mappa varchi e ZTL" linkato da [Polizia Locale](https://www.polizialocalepadova.it/index.php/chi-siamo/43-sanzioni/transiti-ztl/473-varchi-e-ztl) [L]; il PDF non è aperto | PDF, PNG | Non verificata (pagina senza licenza). Una lista GitHub di terzi cita un dataset CC BY 2.5 IT: non verificato | Sì, 32 in elenco testuale senza coordinate [L] | [Ordinanza 437/2023](https://www.comune.padova.it/sites/default/files/attachment/ZTL.pdf) [S, PDF] | solo da ridisegnare da fonte ufficiale | Media |
| Palermo | [Mappa ZTL su sito comunale](https://mobilitasostenibile.comune.palermo.it/maps.php?tp=30) [S: HTTP 302, destinazione non letta]; niente ZTL nella [categoria del portale](https://opendata.comune.palermo.it/opendata-archivio-dataset.php?tema=11) controllata [S] | Mappa web | Non verificata. La stringa "Tutti i diritti riservati" compare in [Info e Mappa](https://repository.comune.palermo.it/polizia-municipale-info.php) e nel portale open data [S]; contesto non letto | Non verificato come dato | [Disciplinare 5/2024](https://ztl.comune.palermo.it/ztl//docs/news/82053/A2024/M08/G07/disciplinare_tecnico_ztl_maggio_2024.pdf) [S, PDF] | da chiedere al Comune | Media |
| Parma | Non trovata. Il [portale](https://opendata.comune.parma.it/dataset) [S] ha 60 dataset CC BY, ZTL non emersa; la mia query API non ha restituito JSON | Non trovato | Non verificata | Elenco in atti comunali [R] | [Turismo, ZTL](https://turismo.comune.parma.it/it/canali-tematici/come-arrivare/mobilita/zone-a-traffico-limitato) [X: certificato non valido] | da chiedere al Comune | Bassa |
| Prato | Non trovata come dato (CKAN [ODN](http://odn.comune.prato.it/api/3/action/package_search?q=ztl) 0 risultati [M]). Mappa interattiva sul sito [R] | Pagine web | Non verificata | Elenco nelle pagine di zona [R] | [Zone a Traffico Limitato](https://www.comune.prato.it/it/muoversi/ztl-ztc/pagina168.html) [S] | solo da ridisegnare da fonte ufficiale | Media |
| Roma | Hub RSM, [feed DCAT](https://data-rsm.opendata.arcgis.com/api/feed/dcat-us/1.1.json) [M]: [Centro diurna, settori](https://data-rsm.opendata.arcgis.com/datasets/rsm::ztl-centro-diurna-settori), [Trastevere diurna](https://data-rsm.opendata.arcgis.com/datasets/rsm::ztl-trastevere-area-diurna), San Lorenzo, Fascia Verde, altre. Le pagine singole non mostrano testo all'estrazione | GeoServices REST; layer **2018-2024** | Feed: `creativecommons.org/licenses/by/4.0` su gran parte; **campo vuoto** su Tridente e Testaccio; `by-sa/4.0` su AF1 VAM. [RSM](https://romamobilita.it/sistemi-e-tecnologie/dataset-geografici/) [L] rimanda invece a CC BY 3.0 IT | Sì: [Centro diurna](https://data-rsm.opendata.arcgis.com/datasets/rsm::varchi-ztl-centro-diurna) e altri layer, stessa licenza del feed | [ZTL in Centro](https://romamobilita.it/muoversi-a-roma/ztl-in-centro/) [S] | riusabile | Media: licenze disomogenee, date vecchie |
| Taranto | Non trovata | Non trovato | Non verificata | Non verificato | [Ecosistema Taranto, ZTL](https://www.ecosistemataranto.it/en/web/ecosistema-taranto-muoversi/ztl) [S]; titolarità del sito non verificata | da chiedere al Comune | Bassa |
| Torino | [Perimetro, varchi e orari](https://aperto.comune.torino.it/dataset/perimetro-varchi-e-orari-ztl) [L]; [XML 5T](https://opendata.5t.torino.it/get_access_control) [L] | XML con perimetro e orari; **validità 2022-2024**, generato 4/2024 | aperTO: "Creative Commons Attribution". [Muoversi a Torino](https://www.muoversiatorino.it/it/open-data/) [L]: IODL v2.0. **Le due pagine divergono** | Sì, 30 con coordinate e direzione [L] | [ZTL Centrale](https://www.comune.torino.it/schede-informative/ztl-centrale) [S] | riusabile | Media: licenza in conflitto, validità scaduta. L'XML ha solo la ZTL Centrale |
| Trento | [ZTL open data](https://dati.trentino.it/dataset/zona-a-traffico-limitato-open-data) [L] | GeoJSON, SHP, KML, CSV; 10/2023 | "Creative Commons CCZero 1.0" | Non nel dataset; il Comune cita una cartografia varchi [R] | [ZTL](https://comune.trento.it/Aree-tematiche/Ambiente-e-territorio/Mobilita-e-traffico-urbano/Ztl) [S] | riusabile | Alta sul perimetro |
| Trieste | Non trovata come dato. [Mappa varchi 2023](https://municipium-images-production.s3-eu-west-1.amazonaws.com/s3/3824/allegati/polizialocale/mappa-ztl-varchi-pilomat-2023.pdf) [S, PDF] | PDF | PDF: non verificata. [Pagina open data](https://dati.comune.trieste.it/gli-open-data-del-comune-di-trieste-e-il-loro-utilizzo/) [L]: IODL 2.0 e CC BY 4.0, ma solo per i dataset del portale | Solo sulla mappa PDF | [Polizia Locale, FAQ](https://polizialocaletrieste.it/domande_frequenti/come-posso-accedere-a-una-ztl-zona-a-traffico-limitato-del-comune-di-trieste/) [S] | solo da ridisegnare da fonte ufficiale | Media |
| Venezia | [ZTL Auto Mestre](https://www.comune.venezia.it/it/content/ztl-centrali-mestre-0) [S], mappa PDF [R]. [dati.venezia.it](https://dati.venezia.it/) [S], non cercato all'interno | PDF | Non verificata | Non verificato | Stessa pagina | solo da ridisegnare da fonte ufficiale | Bassa |
| Verona | [Mappa ZTL con varchi](https://www.comune.verona.it/Amministrazione/Documenti-e-dati/Dataset/Mappa-della-ZTL-con-varchi) [L]; perimetro nel CSV non verificato | [CSV](https://www.comune.verona.it/customexport/dataset-csv_resource-10484) (non aperto), mappa; 6-7/2025 | "Creative Commons Attribution–NonCommercial 4.0 International (CC BY-NC 4.0)". Altre pagine indicano CC0 e IODL 2.0 [R] | Sì, elenco; coordinate non verificate | [La ZTL di Verona](https://www.comune.verona.it/Novita/Notizie/La-Zona-a-Traffico-Limitato-di-Verona) [S] | da chiedere al Comune | Media |
| Villadossola | Non trovata | Non trovato | Non verificata | Non verificato | La [pagina Polizia Municipale](https://www.comune.villadossola.vb.it/it-it/amministrazione/uffici/polizia-municipale-336-1-8fb37af638599a399807dd429062339d) [S] nomina ZTL, senza regole. ZTL attiva non confermata | non trovato | Bassa |

## Note operative

- **Milano:** il Comune [avverte](https://dati.comune.milano.it/en/web/portale-del-dato/w/mappa-dei-varchi-di-area-c-e-area-b-a-milano) [L] che la mappa è informativa e che la cartografia ufficiale è negli atti della Giunta. Il principio vale ovunque: l'app deve dichiarare che fanno fede segnaletica e ordinanze.
- **Milano, orari:** una guida di terzi sostiene che dal 1/1/2026 il ticket Area C valga anche nel weekend, mentre il Comune nei risultati di ricerca dà lunedì-venerdì. Pagina ufficiale non aperta (403): da risolvere prima di scrivere gli orari.
- **Orari:** solo Torino e Bergamo hanno campi orario nei dati. Altrove vanno trascritti dagli atti e versionati con data e fonte.
- **Roma:** escludere il layer `by-sa` finché non è deciso come trattarlo. Per Tridente e Testaccio il campo licenza è vuoto: chiedere conferma a RSM.
- **Verona:** CC BY-NC può creare dubbi anche per una app gratuita. Chiedere chiarimento al Comune, che pubblica licenze diverse su pagine diverse.
- **Attribuzione:** ogni dataset va citato con ente, titolo, licenza e link nella schermata Licenze. Il testo della IODL 2.0 non è stato letto in questa ricerca: verificarne gli obblighi prima di includere Bergamo, e Torino se si segue quella licenza.

## OpenStreetMap

**Non è consulenza legale.** Anche la OSMF ricorda che l'ultima parola spetta a un giudice ([Community Guidelines](https://osmfoundation.org/wiki/Licence/Community_Guidelines)).

**Tagging** ([wiki](https://wiki.openstreetmap.org/wiki/IT:Tag:boundary=limited_traffic_zone)):

- `boundary=limited_traffic_zone` su aree e multipoligoni, stato "in uso". Non influisce su rendering e routing.
- Accesso: `vehicle=private` o `permit`, oppure `motor_vehicle=private` più `moped=yes`.
- Orari: `vehicle:conditional=yes @ (20:00-08:00)`.
- Varchi: nessuno schema specifico. Le telecamere sono punti `man_made=surveillance` con `surveillance:zone=traffic` e relazione `enforcement=access`.

**Completezza in pratica.** Query Overpass del 1/11/2026 sui confini comunali, un conteggio e non una verifica di qualità:

| Oggetti `boundary=limited_traffic_zone` | Comuni |
|---|---|
| 0 | Bergamo, Cesena, Cuorgnè, Messina, Modena, Taranto, Trieste, Villadossola |
| 1 | Bari, Palermo, Trento |
| 2-4 | Catania 2, Torino 2, Venezia 2, Ferrara 3, Padova 3, Verona 3, Milano 4, Parma 4 |
| 5-8 | Bologna 5, Firenze 6, Prato 6, Roma 6, Napoli 8 |
| 15+ | Genova 15, Brescia 18 |

- Copertura disomogenea: 8 comuni su 26 senza alcun oggetto. Molti poligoni non sono stati confrontati con gli atti.
- Gli oggetti `enforcement=access` o `surveillance:zone=traffic` sono un indicatore grezzo dei varchi (Bologna 207, Milano 202, Napoli 76; Prato, Trieste e Cesena 0). Non distinguono le telecamere ZTL dalle altre con certezza.
- Lo "0" di Villadossola e Cuorgnè può dipendere anche dal filtro sull'area, non controllato a parte.
- La tabella Italia della wiki si dichiara completa rispetto a un elenco MIT del 27/1/2025 (circa 350 città), ma è un elenco, non una garanzia sulle geometrie.

**ODbL per un database nell'app** ([testo](https://opendatacommons.org/licenses/odbl/1-0/)):

- **Sostanzialità:** meno di 100 feature, una tantum, non è sostanziale; l'estrazione sistematica di una categoria in un'area lo è, e le piccole estrazioni ripetute contano come una sola ([linea guida](https://osmfoundation.org/w/index.php?mobileaction=toggle_view_desktop&title=Licence%2FCommunity_Guidelines%2FSubstantial_-_Guideline)). Estrarre tutte le ZTL di 26 comuni e aggiornarle ricade qui.
- **Database, non opera prodotta (mia lettura):** la [linea guida Produced Work](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Produced_Work_-_Guideline) distingue in base all'estraibilità dei dati originali e non parla di app. Un GeoJSON o SQLite nel bundle è estraibile: va trattato come database. Una mappa renderizzata sarebbe opera prodotta.
- **Obblighi (4.2, 4.4, 4.6):** distribuire la parte derivata sotto ODbL, includere licenza o URI e avvisi, offrire gratis via internet una copia leggibile da macchina del database derivato o delle modifiche.
- **Attribuzione** ([linee guida](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines)): "OpenStreetMap" visibile sulla mappa senza interazione, con link a `openstreetmap.org/copyright`. Può sparire al primo gesto o dopo 5 secondi, ma le informazioni devono restare facili da trovare.
- **Mix con dati comunali:** i [Regional Cuts e i Collective Database](https://osmfoundation.org/wiki/Licence/Community_Guidelines) permettono OSM in un'area e un altro fornitore in un'altra, senza condividere il secondo. Se un tipo di dato è interamente non OSM dentro un regional cut, la combinazione è collettiva. Quindi: **una sola fonte per tipo di dato per comune**. Correggere un poligono comunale con OSM, o il contrario, rischia di creare un database derivato. La OSMF stessa riconosce [zone grigie](https://osmfoundation.org/wiki/Licensing_Working_Group/Minutes/2024-06-10) [R].
- **Conclusione:** OSM è usabile come riserva, tenuto in un file separato e pubblicato sotto ODbL. Non serve per gli 11 comuni riusabili, salvo i varchi mancanti: lì il mix per tipo di dato va valutato.

## CAD art. 52: open by default

Fonte primaria: [art. 52, d.lgs. 82/2005, Normattiva](https://www.normattiva.it/uri-res/N2Ls?urn:nir:stato:decreto.legislativo:2005-03-07;82!vig=~art52) [L, testo in vigore dal 27/1/2018 secondo la pagina, letto tramite estrazione].

Il comma 2 riguarda "I dati e i documenti che i soggetti di cui all'articolo 2, comma 2, pubblicano, con qualsiasi modalità," "senza l'espressa adozione di una licenza di cui all'articolo 2, comma 1, lettera h)" del d.lgs. 36/2006. In sintesi, questi si considerano rilasciati come dati di tipo aperto, salvo i dati personali.

Possibile uso e limiti:

- Potrebbe coprire mappe PDF e pagine comunali senza licenza espressa, rendendo meno rischioso il ridisegno per i comuni "solo da ridisegnare". Non è una conclusione legale: serve il parere di un avvocato.
- Non basta contro una riserva esplicita o una licenza diversa. "Tutti i diritti riservati" (Palermo) e CC BY-NC (Verona) sono casi da chiarire col Comune.
- Non ho letto art. 1 c. 1 lett. l-bis e l-ter del CAD né il d.lgs. 36/2006, né le note legali dei singoli siti. La stringa "tutti i diritti riservati" è stata cercata solo nelle pagine scaricate.

## Sintesi

- **Riusabili oggi: 11** (Bergamo, Bologna, Cesena, Ferrara, Firenze, Genova, Milano, Modena, Roma, Torino, Trento), tutti con controllo di attualità da fare e varchi mancanti o non verificati a Cesena, Ferrara, Genova, Modena, Trento.
- **Richiedono lavoro: 15**: 6 da ridisegnare (Brescia, Napoli, Padova, Prato, Trieste, Venezia), 7 da chiedere (Bari, Catania, Messina, Palermo, Parma, Taranto, Verona), 2 non trovati (Cuorgnè, Villadossola).
- **Da cui partire: Milano, Firenze, Bologna, Roma, Torino.** Hanno perimetro e varchi con licenza aperta e molti utenti potenziali; Milano e Firenze sono le più aggiornate, Roma e Torino richiedono prima di chiarire licenza e attualità.
