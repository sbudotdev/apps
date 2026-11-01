import Foundation
import Testing
@testable import SbuZTL

/// Every expected answer below comes from issue 624: a verified line, or `.unknown` where the sources stop.
nonisolated struct CitySchedulesTests {
    private static func zone(_ kind: ZoneKind, _ city: City) -> Zone {
        Zone(id: kind.rawValue, city: city, name: kind.rawValue, kind: kind, act: nil, exceptions: nil, section: nil, polygons: RuleEngineTests.square)
    }

    private static func at(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        RuleEngineTests.moment(year, month, day, hour, minute)
    }

    private static let car = RuleEngineTests.car(.petrol, .euro6d)
    private static let moto = Vehicle(nickname: "Moto", kind: .motorcycle, fuel: .petrol, euro: .euro5)

    private static func answer(_ kind: ZoneKind, _ city: City, _ date: Date, vehicle: Vehicle = car) -> Access {
        RuleEngine.verdict(zone: zone(kind, city), vehicle: vehicle, at: date).access
    }

    @Test("Roma, Centro diurna", arguments: [
        (at(2026, 11, 2, 6, 29), Access.off),     // Monday, before
        (at(2026, 11, 2, 6, 30), .forbidden),     // first minute
        (at(2026, 11, 2, 17, 59), .forbidden),
        (at(2026, 11, 2, 18), .off),
        (at(2026, 11, 7, 12), .off),              // Saturday morning
        (at(2026, 11, 7, 14), .forbidden),
        (at(2026, 11, 8, 12), .off),              // Sunday
        (at(2026, 12, 8, 12), .off),              // holiday, excluded
        (at(2026, 6, 29, 12), .unknown),          // patron: the page doesn't say
        (at(2026, 8, 3, 12), .unknown),           // August: "non indicato"
    ])
    func romaCentroDay(date: Date, expected: Access) {
        #expect(Self.answer(.romaCentroDay, .roma, date) == expected)
    }

    @Test("Roma, Centro notturna crosses midnight", arguments: [
        (at(2026, 11, 6, 22, 59), Access.off),
        (at(2026, 11, 6, 23), .forbidden),        // Friday night
        (at(2026, 11, 7, 2, 59), .forbidden),     // the same night, on Saturday
        (at(2026, 11, 7, 3), .off),
        (at(2026, 11, 8, 2), .forbidden),         // Saturday night, on Sunday
        (at(2026, 11, 9, 2), .off),               // Sunday night isn't one
        (at(2026, 8, 7, 23, 30), .off),           // August: "non attiva"
        (at(2026, 8, 1, 1), .unknown),            // from July into August: unsettled
        (at(2026, 12, 25, 23), .off),             // holiday, excluded
        (at(2026, 12, 26, 1), .off),              // a holiday after a holiday
        (at(2026, 12, 8, 1), .off),               // Tuesday: no night to end
        (at(2027, 1, 1, 23), .off),               // Friday, holiday
        (at(2027, 1, 2, 1), .unknown),            // that night, after the holiday: unsettled
    ])
    func romaCentroNight(date: Date, expected: Access) {
        #expect(Self.answer(.romaCentroNight, .roma, date) == expected)
    }

    @Test("Roma, Trastevere notturna includes holidays and adds nights in summer", arguments: [
        (at(2026, 12, 25, 22), Access.forbidden), // Friday and holiday: included
        (at(2026, 5, 6, 22), .forbidden),         // Wednesday in May
        (at(2026, 5, 7, 2), .forbidden),          // the same night
        (at(2026, 11, 4, 22), .off),              // Wednesday in November
        (at(2026, 8, 5, 22), .off),               // August: "non attiva"
        (at(2026, 11, 6, 21, 29), .off),
    ])
    func romaTrastevereNight(date: Date, expected: Access) {
        #expect(Self.answer(.romaTrastevereNight, .roma, date) == expected)
        #expect(Self.answer(.romaSanLorenzoNight, .roma, date) == expected)
    }

    @Test("Roma, the sectors with the Tridente never answer forbidden or allowed", arguments: [
        (at(2026, 11, 2, 18, 30), Access.unknown), // past Centro's hours, within the Tridente's
        (at(2026, 11, 7, 11), .unknown),
        (at(2026, 11, 2, 19), .off),
        (at(2026, 12, 8, 12), .off),
    ])
    func romaTridente(date: Date, expected: Access) {
        #expect(Self.answer(.romaTridenteArea, .roma, date) == expected)
        #expect(Self.answer(.romaTridenteArea, .roma, date, vehicle: Self.moto) == expected)
    }

    @Test("Roma, two wheels are free except where the Tridente may be")
    func romaMoto() {
        #expect(Self.answer(.romaCentroDay, .roma, Self.at(2026, 11, 2, 12), vehicle: Self.moto) == .allowed)
        #expect(Self.answer(.romaTrastevereDay, .roma, Self.at(2026, 11, 2, 7), vehicle: Self.moto) == .allowed)
    }

    @Test("Roma, Fascia Verde by class", arguments: [
        (Vehicle(nickname: "", kind: .car, fuel: .petrol, euro: .euro2), Access.forbidden),
        (Vehicle(nickname: "", kind: .car, fuel: .petrol, euro: .euro3), .allowed),
        (Vehicle(nickname: "", kind: .car, fuel: .diesel, euro: .euro3), .forbidden),
        (Vehicle(nickname: "", kind: .car, fuel: .diesel, euro: .euro4), .allowed),
        (Vehicle(nickname: "", kind: .car, fuel: .gas, euro: .euro2), .unknown),      // exception by registration date
        (Vehicle(nickname: "", kind: .car, fuel: .gas, euro: .euro3), .allowed),
        (Vehicle(nickname: "", kind: .car, fuel: .electric, euro: nil), .unknown),
        (Vehicle(nickname: "", kind: .car, fuel: .hybrid, euro: .euro6d), .unknown),
        (Vehicle(nickname: "", kind: .car, fuel: .petrol, euro: nil), .unknown),
        (Vehicle(nickname: "", kind: .motorcycle, fuel: .petrol, euro: .euro1), .forbidden),
        (Vehicle(nickname: "", kind: .motorcycle, fuel: .petrol, euro: .euro2), .allowed),
        (Vehicle(nickname: "", kind: .moped, fuel: .petrol, euro: .euro2), .unknown),
    ])
    func fasciaVerde(vehicle: Vehicle, expected: Access) {
        #expect(Self.answer(.romaFasciaVerde, .roma, Self.at(2026, 11, 2, 3), vehicle: vehicle) == expected)
    }

    @Test("Roma, Fascia Verde's calendar", arguments: [
        (at(2026, 11, 7, 23), Access.forbidden),  // Saturday, h24
        (at(2026, 11, 8, 12), .off),              // an ordinary Sunday
        (at(2026, 11, 15, 8), .unknown),          // ecological Sunday, within its band
        (at(2026, 11, 15, 13), .off),             // between its bands
        (at(2026, 12, 8, 12), .off),              // midweek holiday
        (at(2026, 12, 26, 12), .unknown),         // holiday on a Saturday
        (at(2027, 6, 29, 12), .unknown),          // patron
        (at(2027, 10, 30, 12), .forbidden),
        (at(2027, 11, 2, 12), .unknown),          // past the stated extension
    ])
    func fasciaVerdeCalendar(date: Date, expected: Access) {
        let old = RuleEngineTests.car(.petrol, .euro1)
        #expect(Self.answer(.romaFasciaVerde, .roma, date, vehicle: old) == expected)
    }

    @Test("Torino, ZTL Centrale", arguments: [
        (at(2026, 11, 2, 7, 29), Access.off),
        (at(2026, 11, 2, 7, 30), .forbidden),
        (at(2026, 11, 2, 10, 29), .forbidden),
        (at(2026, 11, 2, 10, 30), .off),
        (at(2026, 11, 7, 9), .off),               // Saturday
        (at(2026, 12, 8, 9), .off),               // holiday, excluded
        (at(2026, 6, 24, 9), .unknown),           // patron
    ])
    func torino(date: Date, expected: Access) {
        #expect(Self.answer(.torinoCentrale, .torino, date) == expected)
    }

    @Test("Torino, exemptions only where stated")
    func torinoVehicles() {
        let morning = Self.at(2026, 11, 2, 9)
        #expect(Self.answer(.torinoCentrale, .torino, morning, vehicle: Self.moto) == .allowed)
        #expect(Self.answer(.torinoCentrale, .torino, morning, vehicle: RuleEngineTests.car(.electric, .euro6d)) == .unknown)
    }

    @Test("Bologna, Zona T is limited at every hour, holidays included", arguments: [
        at(2026, 11, 2, 12), at(2026, 11, 2, 3), at(2026, 11, 8, 23, 59), at(2026, 12, 25, 0), at(2026, 10, 4, 12),
    ])
    func bolognaT(date: Date) {
        #expect(Self.answer(.bolognaT, .bologna, date) == .forbidden)
        #expect(Self.answer(.bolognaT, .bologna, date, vehicle: Self.moto) == .unknown)
        #expect(Self.answer(.bolognaT, .bologna, date, vehicle: Vehicle(nickname: "", kind: .car, fuel: .electric, euro: nil)) == .unknown)
    }

    @Test("Bologna, what isn't verified answers unknown at every hour", arguments: [
        at(2026, 11, 2, 12), at(2026, 11, 2, 3), at(2026, 11, 8, 12), at(2026, 12, 25, 12),
    ])
    func bolognaUnverified(date: Date) {
        #expect(Self.answer(.bolognaZtl, .bologna, date) == .unknown)
        #expect(Self.answer(.bolognaUnnamed, .bologna, date) == .unknown)
    }

    @Test("A declared permit opens a new city's zone, and only in force", arguments: [ZoneKind.romaCentroDay, .torinoCentrale, .bolognaT])
    func permits(kind: ZoneKind) {
        let city: City = kind == .romaCentroDay ? .roma : kind == .torinoCentrale ? .torino : .bologna
        let zone = Self.zone(kind, city)
        let permit = Permit(vehicleID: Self.car.id, zoneID: zone.id)
        let verdict = RuleEngine.verdict(zone: zone, vehicle: Self.car, at: Self.at(2026, 11, 2, 9), permits: [permit])
        #expect(verdict.access == .allowed)
    }

    @Test("Every answer in the new cities names its source and verification day", arguments: [
        ZoneKind.romaCentroDay, .romaCentroNight, .romaTridenteArea, .romaTrastevereDay, .romaTrastevereNight, .romaSanLorenzoNight, .romaFasciaVerde,
        .torinoCentrale, .bolognaT, .bolognaZtl, .bolognaUnnamed,
    ])
    func sourced(kind: ZoneKind) throws {
        let city: City = "\(kind)".hasPrefix("roma") ? .roma : "\(kind)".hasPrefix("torino") ? .torino : .bologna
        for hour in 0..<24 {
            let source = try #require(RuleEngine.verdict(zone: Self.zone(kind, city), vehicle: Self.car, at: Self.at(2026, 11, 2, hour)).source)
            #expect(source.verified == "2026-11-01")
            #expect(source.url != nil)
        }
    }

    @Test("Bundled perimeters fall in the right city, with the right zones")
    func bundled() {
        let catalog = ZoneCatalog.bundled
        #expect(catalog.zones(in: .bologna).count == 14)
        #expect(catalog.zones(in: .roma).count == 7)
        #expect(catalog.zones(in: .torino).count == 1)
        #expect(catalog.zones(at: Point(44.4945, 11.3430)).contains { $0.kind == .bolognaZtl }) // Piazza Maggiore: the hole is filled
        #expect(catalog.zones(at: Point(44.49538, 11.3399)).contains { $0.kind == .bolognaT })    // Via Ugo Bassi
        #expect(catalog.zones(at: Point(41.8986, 12.4768)).contains { $0.kind == .romaCentroDay }) // Pantheon
        #expect(catalog.zones(at: Point(41.9060, 12.4823)).contains { $0.kind == .romaTridenteArea }) // Piazza di Spagna
        #expect(catalog.zones(at: Point(41.8895, 12.4698)).contains { $0.kind == .romaTrastevereNight }) // Santa Maria in Trastevere
        #expect(catalog.zones(at: Point(41.8975, 12.5155)).contains { $0.kind == .romaSanLorenzoNight })
        #expect(catalog.zones(at: Point(41.9, 12.5)).contains { $0.kind == .romaFasciaVerde })
        #expect(catalog.zones(at: Point(45.0705, 7.6868)).contains { $0.kind == .torinoCentrale }) // Piazza Castello
        for (city, centre) in [(City.bologna, Point(44.4949, 11.3426)), (.roma, Point(41.9, 12.48)), (.torino, Point(45.07, 7.68))] {
            #expect(catalog.city(at: centre) == city)
            #expect(city.missingPerimeters != nil)
            #expect(!Dataset.all(in: city).isEmpty)
        }
    }

    @Test("Parkings: small, in the map's region, none when far out")
    func parkings() {
        let catalog = ParkingCatalog(parkings: [
            Parking(id: 0, point: Point(45.0, 7.0), name: "Vicino"),
            Parking(id: 1, point: Point(45.01, 7.0), name: ""),
            Parking(id: 2, point: Point(46.0, 7.0), name: "Lontano"),
        ])
        #expect(catalog.visible(latitude: 45.0, longitude: 7.0, latitudeDelta: 0.04, longitudeDelta: 0.04).map(\.id) == [0, 1])
        #expect(catalog.visible(latitude: 45.0, longitude: 7.0, latitudeDelta: 0.5, longitudeDelta: 0.5).isEmpty)
        #expect(ParkingCatalog.bundled.parkings.count > 1000)
        let tooMany = ParkingCatalog(parkings: (0..<400).map { Parking(id: $0, point: Point(45.0, 7.0), name: "") })
        #expect(tooMany.visible(latitude: 45.0, longitude: 7.0, latitudeDelta: 0.04, longitudeDelta: 0.04).count == 150)
    }
}
