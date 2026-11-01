import Foundation

/// Answers "can this vehicle enter this zone at this moment?".
/// Bologna, Roma and Torino answer from `ZoneRule.table`. Milano and Firenze stay in code: Euro calendars and seasons by relative date, tested as they are.
nonisolated enum RuleEngine {
    static func verdict(zone: Zone, vehicle: Vehicle, at date: Date, permits: [Permit] = []) -> Verdict {
        switch zone.kind {
        case .areaC: milanArea(.areaC, vehicle: vehicle, at: date, permits: permits, zone: zone)
        case .areaB: milanArea(.areaB, vehicle: vehicle, at: date, permits: permits, zone: zone)
        case .florenceSector: florence(zone: zone, vehicle: vehicle, at: date, permits: permits)
        case .pedestrian:
            declared(permits, vehicle, zone) ?? Verdict(
                access: .forbidden, reason: "Area pedonale. Le deroghe sono quelle dell'atto.", source: .milanoData)
        case .ztl, .noTransit, .other:
            declared(permits, vehicle, zone) ?? Verdict(
                access: .unknown, reason: "Non ho orari verificati per questa zona. Segui la segnaletica.", source: .milanoData)
        case .romaFasciaVerde: fasciaVerde(zone: zone, vehicle: vehicle, at: date, permits: permits)
        case .romaCentroDay, .romaCentroNight, .romaTridenteArea, .romaTrastevereDay, .romaTrastevereNight, .romaSanLorenzoNight,
             .torinoCentrale, .bolognaT, .bolognaZtl, .bolognaUnnamed:
            scheduled(zone: zone, vehicle: vehicle, at: date, permits: permits)
        }
    }

    /// The most restrictive answer among several zones on the same point.
    static func worst(_ verdicts: [Verdict]) -> Verdict? {
        verdicts.max { rank($0.access) < rank($1.access) }
    }

    private static func rank(_ access: Access) -> Int {
        switch access {
        case .off: 0
        case .allowed: 1
        case .paid: 2
        case .unknown: 3
        case .forbidden: 4
        }
    }

    private static func declared(_ permits: [Permit], _ vehicle: Vehicle, _ zone: Zone) -> Verdict? {
        guard permits.contains(where: { $0.vehicleID == vehicle.id && $0.zoneID == zone.id }) else { return nil }
        return Verdict(access: .allowed, reason: "Hai dichiarato un permesso per questa zona.", source: nil)
    }

    private static func scheduled(zone: Zone, vehicle: Vehicle, at date: Date, permits: [Permit]) -> Verdict {
        guard let rule = ZoneRule.table[zone.kind] else {
            return Verdict(access: .unknown, reason: "Non ho orari verificati per questa zona. Segui la segnaletica.", source: nil)
        }
        let state = rule.schedule.state(at: date, city: zone.city)
        if state == .off {
            return Verdict(access: .off, reason: rule.offReason, source: rule.source)
        }
        if let held = declared(permits, vehicle, zone) { return held }
        if state == .unverified {
            return Verdict(access: .unknown, reason: "Per questo giorno le fonti non dicono se vale. Segui la segnaletica.", source: rule.source)
        }
        guard vehicle.kind == .car else {
            return Verdict(access: rule.twoWheels, reason: rule.twoWheelsReason, source: rule.source)
        }
        if rule.unverifiedFuels.contains(vehicle.fuel) {
            return Verdict(access: .unknown, reason: "Per questa alimentazione non ho letto una regola certa.", source: rule.source)
        }
        return Verdict(access: rule.car, reason: rule.carReason, source: rule.source)
    }

    private static func fasciaVerde(zone: Zone, vehicle: Vehicle, at date: Date, permits: [Permit]) -> Verdict {
        let source = RuleSource.romaFasciaVerde
        if FasciaVerde.isExpired(date) {
            return Verdict(access: .unknown, reason: "La proroga che ho letto finisce il 31 ottobre 2027. Segui la segnaletica.", source: source)
        }
        if FasciaVerde.isEcoSundayBand(date) {
            return Verdict(access: .unknown, reason: "Domenica ecologica: veicoli e deroghe li decide ogni volta un'ordinanza. Segui la segnaletica.", source: source)
        }
        let state = FasciaVerde.schedule.state(at: date, city: zone.city)
        if state == .off {
            return Verdict(access: .off, reason: "In vigore dal lunedì al sabato 24 ore su 24, esclusi i festivi infrasettimanali.", source: source)
        }
        if let held = declared(permits, vehicle, zone) { return held }
        if state == .unverified {
            return Verdict(access: .unknown, reason: "Per questo giorno le fonti non dicono se vale. Segui la segnaletica.", source: source)
        }
        switch FasciaVerde.isBanned(vehicle) {
        case true?: return Verdict(access: .forbidden, reason: "Vietata a questa classe Euro nei giorni in vigore.", source: source)
        case false?: return Verdict(access: .allowed, reason: "Questa classe non è vietata in Fascia Verde. Le ZTL hanno regole proprie.", source: source)
        case nil: return Verdict(access: .unknown, reason: "Per questa alimentazione non ho letto una regola certa.", source: source)
        }
    }

    private enum MilanArea { case areaB, areaC }

    private static func milanArea(_ area: MilanArea, vehicle: Vehicle, at date: Date, permits: [Permit], zone: Zone) -> Verdict {
        let source: RuleSource = area == .areaC ? .areaC : .areaB
        if Holidays.isPatron(date, city: .milano) {
            return Verdict(access: .unknown, reason: "Oggi è il patrono: l'atto non lo cita. Segui la segnaletica.", source: source)
        }
        let c = Holidays.calendar.dateComponents([.weekday, .hour, .minute], from: date)
        let minutes = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        let weekday = c.weekday ?? 1
        let inForce = (2...6).contains(weekday) && !Holidays.isNational(date) && minutes >= 450 && minutes < 1170
        guard inForce else {
            return Verdict(access: .off, reason: "In vigore dal lunedì al venerdì, 7:30-19:30, festivi esclusi.", source: source)
        }
        if let held = declared(permits, vehicle, zone) { return held }
        guard vehicle.kind == .car else {
            return Verdict(access: .unknown, reason: "Per moto e ciclomotori le date dei divieti non sono confermate.", source: source)
        }
        guard vehicle.fuel == .petrol || vehicle.fuel == .diesel, let euro = vehicle.euro else {
            return Verdict(access: .unknown, reason: "Per questa alimentazione non ho letto una regola certa.", source: source)
        }
        let ban = area == .areaC ? EmissionBans.areaC(fuel: vehicle.fuel, euro: euro) : EmissionBans.areaB(fuel: vehicle.fuel, euro: euro)
        if let ban, ban <= date {
            return Verdict(access: .forbidden, reason: "Vietata a questa classe Euro nei giorni e negli orari in vigore.", source: source)
        }
        return area == .areaC
            ? Verdict(access: .paid(euros: Decimal(string: "7.50") ?? 0), reason: "Si entra pagando il ticket giornaliero.", source: source)
            : Verdict(access: .allowed, reason: "Questa classe Euro non è vietata.", source: source)
    }

    private static func florence(zone: Zone, vehicle: Vehicle, at date: Date, permits: [Permit]) -> Verdict {
        if let held = declared(permits, vehicle, zone) { return held }
        if Holidays.isNational(date) || Holidays.isPatron(date, city: .firenze) {
            return Verdict(access: .unknown, reason: "Per i festivi non ho una fonte certa. Segui la segnaletica.", source: .firenze)
        }
        guard vehicle.kind == .car else {
            return Verdict(access: .unknown, reason: "Per moto e ciclomotori non ho una fonte certa.", source: .firenze)
        }
        guard florenceInForce(at: date) else {
            return Verdict(access: .off, reason: "Non in vigore a quest'ora.", source: .firenze)
        }
        return Verdict(access: .forbidden, reason: "Serve un permesso per questo settore.", source: .firenze)
    }

    /// Monday to Friday 7:30-20, Saturday 7:30-16, plus Thursday to Saturday nights 23-3 in summer.
    static func florenceInForce(at date: Date) -> Bool {
        let calendar = Holidays.calendar
        let c = calendar.dateComponents([.year, .weekday, .hour, .minute], from: date)
        let minutes = (c.hour ?? 0) * 60 + (c.minute ?? 0)
        let weekday = c.weekday ?? 1
        if (2...6).contains(weekday), minutes >= 450, minutes < 1200 { return true }
        if weekday == 7, minutes >= 450, minutes < 960 { return true }
        // The small hours belong to the night that started the day before.
        let night = minutes < 180 ? calendar.date(byAdding: .day, value: -1, to: date) ?? date : date
        guard minutes >= 1380 || minutes < 180 else { return false }
        let nightWeekday = calendar.component(.weekday, from: night)
        guard [5, 6, 7].contains(nightWeekday), let year = c.year else { return false }
        return summerNights(year: year).contains(calendar.startOfDay(for: night))
    }

    /// First Thursday of April to first Sunday of October.
    private static func summerNights(year: Int) -> ClosedRange<Date> {
        let calendar = Holidays.calendar
        let start = calendar.date(from: DateComponents(year: year, month: 4, weekday: 5, weekdayOrdinal: 1)) ?? .distantPast
        let end = calendar.date(from: DateComponents(year: year, month: 10, weekday: 1, weekdayOrdinal: 1)) ?? .distantPast
        return start...max(start, end)
    }
}
