import Foundation

extension ShieldSettings {
    /// The made-up Shield of screenshots and UI tests: names only, since real apps come from
    /// Screen Time on a device.
    nonisolated static func sample(now: Date = .now, calendar: Calendar = .current) -> ShieldSettings {
        let today = Day(now, calendar: calendar)
        var settings = ShieldSettings()
        settings.isSetUp = true
        settings.put(Intention(name: "Instagram", maxOpens: 10, minutes: 10, opensDay: today, opens: 3))
        settings.put(Intention(name: "YouTube", maxOpens: 5, minutes: 15, days: [2, 3, 4, 5, 6], opensDay: today, opens: 1))
        // Notte, turned off so that no screenshot depends on the hour it is taken.
        var night = BlockSession.presets[2]
        night.isOn = false
        settings.put(night)
        return settings
    }
}
