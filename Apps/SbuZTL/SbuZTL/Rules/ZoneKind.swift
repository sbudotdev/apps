/// What the act calls the zone.
nonisolated enum ZoneKind: String, Codable, Sendable {
    case areaB
    case areaC
    case ztl
    case pedestrian
    case noTransit
    case other
    case florenceSector
    case romaCentroDay
    case romaCentroNight
    /// Sectors A and C, which contain the Tridente: its own perimeter has no declared licence.
    case romaTridenteArea
    case romaTrastevereDay
    case romaTrastevereNight
    case romaSanLorenzoNight
    case romaFasciaVerde
    case torinoCentrale
    case bolognaZtl
    case bolognaT
    /// A record of the official dataset without a name.
    case bolognaUnnamed
}
