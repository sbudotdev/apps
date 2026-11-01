import Foundation

/// The bundled timetables, from issue 624 of the tracker, read on 1/11/2026. Updated only with app releases.
/// A gap in the sources stays `.unknown` here: an absence from a list is not a rule.
nonisolated extension ZoneRule {
    static let table: [ZoneKind: ZoneRule] = [
        .romaCentroDay: roma(
            Schedule(windows: [ScheduleWindow(days: ScheduleWindow.mondayToFriday, start: 390, end: 1080), ScheduleWindow(days: [7], start: 840, end: 1080)], silentMonths: [8]),
            off: "In vigore dal lunedì al venerdì 6:30-18, sabato 14-18, festivi esclusi."),
        .romaCentroNight: roma(
            Schedule(windows: [ScheduleWindow(days: [6, 7], start: 1380, end: 180)], closedMonths: [8]),
            off: "In vigore venerdì e sabato 23-3, festivi esclusi. Ad agosto non è attiva."),
        .romaTridenteArea: ZoneRule(
            schedule: Schedule(windows: [ScheduleWindow(days: ScheduleWindow.mondayToFriday, start: 390, end: 1140), ScheduleWindow(days: [7], start: 600, end: 1140)], silentMonths: [8]),
            car: .unknown, carReason: "Qui può esserci il Tridente, attivo in questo orario. Non ho il suo perimetro: segui la segnaletica.",
            twoWheels: .unknown, twoWheelsReason: "Qui può esserci il Tridente, dove anche le moto hanno bisogno del permesso. Non ho il suo perimetro: segui la segnaletica.",
            offReason: "Il Tridente vale dal lunedì al venerdì 6:30-19, sabato 10-19, festivi esclusi.", source: .romaZtl),
        .romaTrastevereDay: roma(
            Schedule(windows: [ScheduleWindow(days: ScheduleWindow.mondayToSaturday, start: 390, end: 600)], silentMonths: [8]),
            off: "In vigore dal lunedì al sabato 6:30-10, festivi esclusi."),
        .romaTrastevereNight: roma(romaLateNights, off: "In vigore venerdì e sabato 21:30-3, da maggio a ottobre anche mercoledì e giovedì. Ad agosto non è attiva."),
        .romaSanLorenzoNight: roma(romaLateNights, off: "In vigore venerdì e sabato 21:30-3, da maggio a ottobre anche mercoledì e giovedì. Ad agosto non è attiva."),
        .torinoCentrale: ZoneRule(
            schedule: Schedule(windows: [ScheduleWindow(days: ScheduleWindow.mondayToFriday, start: 450, end: 630)]),
            car: .forbidden, carReason: "Serve un permesso. Alcuni casi si regolarizzano comunicando la targa a GTT entro 10 giorni.",
            twoWheels: .allowed, twoWheelsReason: "Moto e ciclomotori sono esenti in ZTL Centrale.",
            unverifiedFuels: [.electric, .hybrid],
            offReason: "In vigore dal lunedì al venerdì 7:30-10:30, festivi esclusi.", source: .torinoCentrale),
        .bolognaT: ZoneRule(
            schedule: Schedule(windows: [ScheduleWindow(days: ScheduleWindow.everyDay, start: 0, end: 1440)], holidays: .included),
            car: .forbidden, carReason: "La Zona T è limitata tutti i giorni, 24 ore su 24. Serve un'autorizzazione.",
            twoWheels: .unknown, twoWheelsReason: "Per moto e ciclomotori non ho una fonte certa.",
            unverifiedFuels: [.electric, .hybrid],
            offReason: "La Zona T è limitata tutti i giorni, 24 ore su 24.", source: .bolognaZtl),
        // 20-7 is free in the ambient ZTL, but the h24 special zones inside it have no bundled perimeter: no hour can be called off.
        .bolognaZtl: ZoneRule(
            schedule: Schedule(windows: [ScheduleWindow(days: ScheduleWindow.everyDay, start: 0, end: 1440)], holidays: .included),
            car: .unknown, carReason: "La limitazione è 7-20, ma non ho una fonte letta sui giorni. Dentro ci sono zone attive 24 ore su 24 senza perimetro.",
            twoWheels: .unknown, twoWheelsReason: "La limitazione è 7-20, ma per moto e ciclomotori non ho una fonte certa.",
            offReason: "Non ho orari verificati per questa zona. Segui la segnaletica.", source: .bolognaZtl),
        .bolognaUnnamed: ZoneRule(
            schedule: Schedule(windows: [ScheduleWindow(days: ScheduleWindow.everyDay, start: 0, end: 1440)], holidays: .included),
            car: .unknown, carReason: "Il perimetro ufficiale non ha un nome: non so quali regole ha. Segui la segnaletica.",
            twoWheels: .unknown, twoWheelsReason: "Il perimetro ufficiale non ha un nome: non so quali regole ha. Segui la segnaletica.",
            offReason: "Non ho orari verificati per questa zona. Segui la segnaletica.", source: .bolognaData),
    ]

    private static let romaLateNights = Schedule(
        windows: [ScheduleWindow(days: [6, 7], start: 1290, end: 180), ScheduleWindow(days: [4, 5], start: 1290, end: 180, months: Set(5...10))],
        holidays: .included, closedMonths: [8])

    private static func roma(_ schedule: Schedule, off: LocalizedStringResource) -> ZoneRule {
        ZoneRule(schedule: schedule,
                 car: .forbidden, carReason: "Serve un permesso. Esenti taxi, NCC e CUDE con il titolare a bordo.",
                 twoWheels: .allowed, twoWheelsReason: "Moto e ciclomotori sono liberi in questa ZTL.",
                 unverifiedFuels: [.hybrid], offReason: off, source: .romaZtl)
    }
}
