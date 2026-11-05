import Foundation

extension BlockSession {
    /// The start as today's date, for a time picker.
    var startDate: Date {
        get { Self.date(start) }
        set { start = Self.minutes(newValue) }
    }

    /// The end as today's date, for a time picker.
    var endDate: Date {
        get { Self.date(end) }
        set { end = Self.minutes(newValue) }
    }

    /// "9:30 – 17:00", in the user's clock.
    var hours: String {
        let style = Date.FormatStyle.dateTime.hour().minute()
        return "\(startDate.formatted(style)) – \(endDate.formatted(style))"
    }

    private static func date(_ minutes: Int) -> Date {
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now) ?? .now
    }

    private static func minutes(_ date: Date) -> Int {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }
}
