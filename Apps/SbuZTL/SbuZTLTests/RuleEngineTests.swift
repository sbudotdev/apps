import Foundation
import Testing
@testable import SbuZTL

nonisolated struct RuleEngineTests {
    static let square = [Polygon(ring: [Point(0, 0), Point(0, 1), Point(1, 1), Point(1, 0)])]
    static let areaC = Zone(id: "c", city: .milano, name: "Area C", kind: .areaC, act: nil, exceptions: nil, section: nil, polygons: square)
    static let areaB = Zone(id: "b", city: .milano, name: "Area B", kind: .areaB, act: nil, exceptions: nil, section: nil, polygons: square)
    static let sector = Zone(id: "a", city: .firenze, name: "Settore A", kind: .florenceSector, act: nil, exceptions: nil, section: nil, polygons: square)

    static func car(_ fuel: Fuel, _ euro: EuroClass) -> Vehicle {
        Vehicle(nickname: "Auto", kind: .car, fuel: fuel, euro: euro)
    }

    nonisolated static func moment(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        Holidays.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    // Monday 2 November 2026 at noon.
    static let monday = moment(2026, 11, 2, 12)

    @Test("Area C by Euro class on a working day", arguments: [
        (Fuel.petrol, EuroClass.euro3, Access.forbidden),
        (.petrol, .euro4, .paid(euros: Decimal(string: "7.50")!)),
        (.petrol, .euro5, .paid(euros: Decimal(string: "7.50")!)),
        (.diesel, .euro5, .forbidden),
        (.diesel, .euro6abc, .paid(euros: Decimal(string: "7.50")!)),
    ])
    func areaCByClass(fuel: Fuel, euro: EuroClass, expected: Access) {
        #expect(RuleEngine.verdict(zone: Self.areaC, vehicle: Self.car(fuel, euro), at: Self.monday).access == expected)
    }

    @Test("A future ban applies from its own date")
    func futureBan() {
        let car = Self.car(.petrol, .euro4)
        let before = Self.moment(2027, 9, 30, 12)
        let after = Self.moment(2027, 10, 1, 12)
        #expect(RuleEngine.verdict(zone: Self.areaC, vehicle: car, at: before).access != .forbidden)
        #expect(RuleEngine.verdict(zone: Self.areaC, vehicle: car, at: after).access == .forbidden)
    }

    @Test("Area C is off at the edges of its hours, at weekends and on holidays", arguments: [
        moment(2026, 11, 2, 7, 29), moment(2026, 11, 2, 19, 30), moment(2026, 11, 7, 12), moment(2026, 11, 8, 12), moment(2026, 12, 25, 12), moment(2027, 3, 29, 12),
    ])
    func areaCOff(date: Date) {
        #expect(RuleEngine.verdict(zone: Self.areaC, vehicle: Self.car(.petrol, .euro3), at: date).access == .off)
    }

    @Test("Area C is on at its first minute")
    func areaCOn() {
        #expect(RuleEngine.verdict(zone: Self.areaC, vehicle: Self.car(.petrol, .euro3), at: Self.moment(2026, 11, 2, 7, 30)).access == .forbidden)
    }

    @Test("Area B allows what it doesn't ban")
    func areaB() {
        #expect(RuleEngine.verdict(zone: Self.areaB, vehicle: Self.car(.petrol, .euro5), at: Self.monday).access == .allowed)
        #expect(RuleEngine.verdict(zone: Self.areaB, vehicle: Self.car(.petrol, .euro3), at: Self.monday).access == .forbidden)
    }

    @Test("The patron's day and unread cases answer unknown, never yes")
    func unknowns() {
        let patron = Self.moment(2026, 12, 7, 12)
        #expect(RuleEngine.verdict(zone: Self.areaC, vehicle: Self.car(.petrol, .euro6d), at: patron).access == .unknown)
        let moto = Vehicle(nickname: "Moto", kind: .motorcycle, fuel: .petrol, euro: .euro3)
        #expect(RuleEngine.verdict(zone: Self.areaC, vehicle: moto, at: Self.monday).access == .unknown)
        let gas = Self.car(.gas, .euro5)
        #expect(RuleEngine.verdict(zone: Self.areaB, vehicle: gas, at: Self.monday).access == .unknown)
    }

    @Test("A declared permit opens the zone only for its vehicle")
    func permits() {
        let car = Self.car(.petrol, .euro3)
        let permit = Permit(vehicleID: car.id, zoneID: Self.areaC.id)
        #expect(RuleEngine.verdict(zone: Self.areaC, vehicle: car, at: Self.monday, permits: [permit]).access == .allowed)
        #expect(RuleEngine.verdict(zone: Self.areaC, vehicle: Self.car(.petrol, .euro3), at: Self.monday, permits: [permit]).access == .forbidden)
    }

    @Test("Florence hours and summer nights", arguments: [
        (moment(2026, 11, 2, 12), true),   // Monday noon
        (moment(2026, 11, 2, 20), false),  // Monday 20:00
        (moment(2026, 11, 7, 15, 59), true),  // Saturday
        (moment(2026, 11, 7, 16), false),
        (moment(2026, 11, 8, 12), false),  // Sunday
        (moment(2026, 7, 9, 23, 30), true),   // Thursday night in July
        (moment(2026, 7, 10, 2, 30), true),   // the same night, after midnight
        (moment(2026, 7, 6, 23, 30), false),  // Monday night
        (moment(2026, 12, 10, 23, 30), false), // Thursday night in December
    ])
    func florence(date: Date, expected: Bool) {
        #expect(RuleEngine.florenceInForce(at: date) == expected)
    }

    @Test("The worst answer wins among overlapping zones")
    func worst() {
        let off = Verdict(access: .off, reason: "a", source: nil)
        let forbidden = Verdict(access: .forbidden, reason: "b", source: nil)
        let unknown = Verdict(access: .unknown, reason: "c", source: nil)
        #expect(RuleEngine.worst([off, unknown, forbidden])?.access == .forbidden)
        #expect(RuleEngine.worst([off, unknown])?.access == .unknown)
    }

    @Test("Bundled zones load, and every one answers")
    func bundled() throws {
        let catalog = ZoneCatalog.bundled
        #expect(catalog.zones.count > 200)
        let duomo = Point(45.4642, 9.1900)
        let here = catalog.zones(at: duomo)
        #expect(here.contains { $0.kind == .areaC })
        #expect(here.contains { $0.kind == .areaB })
        #expect(catalog.city(at: duomo) == .milano)
        #expect(catalog.city(at: Point(40.85, 14.27)) == nil) // Napoli
    }
}
