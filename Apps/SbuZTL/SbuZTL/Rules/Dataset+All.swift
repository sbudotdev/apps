import Foundation

nonisolated extension Dataset {
    /// Roma: the DCAT feed says CC BY 4.0 for these layers, the RSM page CC BY 3.0 IT. Torino: aperTO says Creative Commons Attribution, Muoversi a Torino IODL v2.0.
    /// Roma's Tridente and Testaccio layers have an empty licence field and the by-sa AF1 VAM layer is left out: none of them is bundled.
    static let all: [Dataset] = [
        row("Comune di Milano", "Aree pedonali e ZTL", "Creative Commons Attribution", "https://dati.comune.milano.it/dataset/ds51_trafficotrasporti_aree_pedonali_ztl", .milano),
        row("Comune di Firenze", "ZTL diurna", "CC BY 4.0", "https://opendata.comune.fi.it/page_dataset_show?id=9257a75e-3af3-4845-b37d-1540be29115a", .firenze),
        row("Comune di Firenze", "ZTL notturna", "CC BY 4.0", "https://opendata.comune.fi.it/page_dataset_show?id=3d586fa5-7367-42c5-b5f2-d8348a5da431", .firenze),
        row("Comune di Bologna", "Zona a traffico limitato (ZTL)", "CC BY 4.0", "https://opendata.comune.bologna.it/explore/dataset/zona-a-traffico-limitato/", .bologna),
        row("Comune di Bologna", "Zona T centro storico", "CC BY 4.0", "https://opendata.comune.bologna.it/explore/dataset/zona-t-centro-storico/", .bologna),
        row("Roma Servizi per la Mobilità", "ZTL centro diurna (ZTL C bus turistici)", "CC BY 4.0", "https://data-rsm.opendata.arcgis.com/datasets/rsm::ztl-centro-diurna-ztl-c-bus-turistici", .roma),
        row("Roma Servizi per la Mobilità", "ZTL centro diurna - settori", "CC BY 4.0", "https://data-rsm.opendata.arcgis.com/datasets/rsm::ztl-centro-diurna-settori", .roma),
        row("Roma Servizi per la Mobilità", "Centro notturna area", "CC BY 4.0", "https://data-rsm.opendata.arcgis.com/datasets/rsm::centro-notturna-area", .roma),
        row("Roma Servizi per la Mobilità", "ZTL Trastevere - area diurna", "CC BY 4.0", "https://data-rsm.opendata.arcgis.com/datasets/rsm::ztl-trastevere-area-diurna", .roma),
        row("Roma Servizi per la Mobilità", "ZTL Trastevere - area notturna", "CC BY 4.0", "https://data-rsm.opendata.arcgis.com/datasets/rsm::ztl-trastevere-area-notturna", .roma),
        row("Roma Servizi per la Mobilità", "ZTL San Lorenzo - confini", "CC BY 4.0", "https://data-rsm.opendata.arcgis.com/datasets/rsm::ztl-san-lorenzo-confini", .roma),
        row("Roma Servizi per la Mobilità", "ZTL Fascia Verde Confine", "CC BY 4.0", "https://data-rsm.opendata.arcgis.com/datasets/rsm::ztl-fascia-verde-confine", .roma),
        row("Comune di Torino, 5T", "Perimetro, varchi e orari ZTL", "Creative Commons Attribution", "https://aperto.comune.torino.it/dataset/perimetro-varchi-e-orari-ztl", .torino),
    ].compactMap(\.self)

    private static func row(_ entity: String, _ title: String, _ licence: String, _ url: String, _ city: City) -> Dataset? {
        URL(string: url).map { Dataset(entity: entity, title: title, licence: licence, url: $0, city: city) }
    }
}
