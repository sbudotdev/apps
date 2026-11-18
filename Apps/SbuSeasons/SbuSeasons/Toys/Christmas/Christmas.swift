import CoreGraphics
import Foundation

/// Le date del Natale: lo stesso periodo delle app iPhone (dal 1° dicembre all'Epifania), la vigilia, il conto alla rovescia.
nonisolated enum ChristmasDates {
    /// Dal 1° dicembre al 6 gennaio compresi: Babbo Natale passa da solo.
    static func isChristmasTime(_ date: Date, calendar: Calendar = .current) -> Bool {
        let parts = calendar.dateComponents([.month, .day], from: date)
        return parts.month == 12 || (parts.month == 1 && (parts.day ?? 99) <= 6)
    }

    static func isEve(_ date: Date, calendar: Calendar = .current) -> Bool {
        let parts = calendar.dateComponents([.month, .day], from: date)
        return parts.month == 12 && parts.day == 24
    }

    /// Giorni, ore e minuti alla mezzanotte del prossimo 25 dicembre. nil il giorno di Natale.
    static func countdown(from date: Date, calendar: Calendar = .current) -> DateComponents? {
        let parts = calendar.dateComponents([.month, .day], from: date)
        guard !(parts.month == 12 && parts.day == 25),
              let christmas = calendar.nextDate(after: date, matching: DateComponents(month: 12, day: 25, hour: 0, minute: 0, second: 0),
                                                matchingPolicy: .nextTime)
        else { return nil }
        return calendar.dateComponents([.day, .hour, .minute], from: date, to: christmas)
    }
}

/// Un regalo al giorno, per tutti gli schermi: il giorno dell'ultimo regalo si salva in UserDefaults.
nonisolated struct GiftDiary {
    private static let key = "lastGiftDay"
    let defaults: UserDefaults
    var calendar: Calendar = .current

    func canGive(on date: Date) -> Bool { defaults.string(forKey: Self.key) != day(date) }
    func recordGift(on date: Date) { defaults.set(day(date), forKey: Self.key) }

    private func day(_ date: Date) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return "\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }
}

/// Quando passa Babbo Natale e se porta il regalo.
nonisolated enum SantaVisits {
    /// Di solito un passaggio su due lascia il regalo (se oggi non l'ha già lasciato); la vigilia sempre.
    static func carriesGift(eve: Bool, canGive: Bool, roll: Double) -> Bool {
        canGive && (eve || roll < Tuning.santaGiftChance)
    }
}

/// Che giorno è e il diario dei regali: la scena li legge da qui, i test li sostituiscono.
struct ChristmasClock {
    var now: () -> Date = Date.init
    var calendar: Calendar = .current
    var diary = GiftDiary(defaults: .standard)

    var isChristmasTime: Bool { ChristmasDates.isChristmasTime(now(), calendar: calendar) }
    var isEve: Bool { ChristmasDates.isEve(now(), calendar: calendar) }
}
