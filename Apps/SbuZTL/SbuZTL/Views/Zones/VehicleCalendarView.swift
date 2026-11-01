import SbuKit
import SwiftUI

/// The next two weeks for one vehicle and one zone, a line per day. Every stretch is also in words.
struct VehicleCalendarView: View {
    let zone: Zone
    let vehicle: Vehicle
    let permits: [Permit]

    var body: some View {
        List(VehicleCalendar.days(from: .now), id: \.self) { day in
            VStack(alignment: .leading, spacing: SbuTheme.space2) {
                Text(day.formatted(Date.FormatStyle(timeZone: Holidays.calendar.timeZone).weekday(.wide).day().month(.wide)))
                    .font(SbuTheme.headline)
                ForEach(VehicleCalendar.spans(zone: zone, vehicle: vehicle, day: day, permits: permits)) { span in
                    HStack(spacing: SbuTheme.space2) {
                        Image(systemName: span.access.symbol).foregroundStyle(span.access.tint)
                        Text(Self.time(span.startMinute) + "-" + Self.time(span.endMinute))
                            .font(SbuTheme.subheadline)
                            .monospacedDigit()
                        Text(span.access.headline)
                            .font(SbuTheme.subheadline)
                            .foregroundStyle(SbuTheme.inkMuted)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .navigationTitle(vehicle.nickname.isEmpty ? zone.name : vehicle.nickname)
        .navigationBarTitleDisplayMode(.inline)
    }

    private static func time(_ minute: Int) -> String {
        Duration.seconds(minute * 60).formatted(.time(pattern: .hourMinute))
    }
}
