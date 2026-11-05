import DeviceActivity
import Foundation

extension DeviceActivitySchedule {
    /// A schedule that runs once, between two moments.
    ///
    /// Screen Time schedules last at least 15 minutes. For anything shorter, such as an opening of
    /// a few minutes, make the moment you wait for the *start* of a one-off schedule: the monitor
    /// extension is called when it begins.
    nonisolated static func oneOff(from start: Date, to end: Date, calendar: Calendar = .current) -> DeviceActivitySchedule {
        let parts: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
        return DeviceActivitySchedule(intervalStart: calendar.dateComponents(parts, from: start),
                                      intervalEnd: calendar.dateComponents(parts, from: end),
                                      repeats: false)
    }
}
