import SbuKit
import SwiftUI

/// The days something holds, one checkbox per weekday, from the locale's first day of the week.
struct WeekdaysPicker: View {
    @Binding var days: Set<Int>

    private var weekdays: [(number: Int, name: String)] {
        let calendar = Calendar.current
        let names = calendar.standaloneWeekdaySymbols
        return (0..<7).map { offset in
            let number = (calendar.firstWeekday - 1 + offset) % 7 + 1
            return (number, names[number - 1])
        }
    }

    var body: some View {
        DisclosureGroup("Giorni: \(days.count)") {
            ForEach(weekdays, id: \.number) { day in
                Toggle(day.name.capitalized, isOn: Binding {
                    days.contains(day.number)
                } set: { isOn in
                    if isOn { days.insert(day.number) } else { days.remove(day.number) }
                })
                .toggleStyle(SbuCheckboxStyle())
            }
        }
    }
}

#Preview("Light") {
    WeekdaysPicker(days: .constant([2, 3, 4, 5, 6]))
        .padding()
}

#Preview("Dark") {
    WeekdaysPicker(days: .constant([2, 3, 4, 5, 6]))
        .padding()
        .preferredColorScheme(.dark)
}
