import SbuKit
import SwiftUI

/// Pick the moment the answers are for, on Italian time, with a way back to now.
struct TimePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var departure: Date?
    @State private var draft = Date.now

    var body: some View {
        NavigationStack {
            VStack(spacing: SbuTheme.space4) {
                DatePicker("Quando guidi", selection: $draft, in: Date.now..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .environment(\.timeZone, Holidays.calendar.timeZone)
                SbuButton("Conferma") {
                    departure = draft
                    dismiss()
                }
                SbuButton("Torna ad adesso", kind: .secondary) {
                    departure = nil
                    dismiss()
                }
                Spacer()
            }
            .padding(SbuTheme.space4)
            .background(SbuTheme.paper)
            .navigationTitle("Quando guidi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Chiudi", systemImage: "xmark") { dismiss() }
                }
            }
            .onAppear { draft = departure ?? .now }
        }
    }
}

#Preview("Light") {
    TimePickerSheet(departure: .constant(nil))
}

#Preview("Dark") {
    TimePickerSheet(departure: .constant(nil))
        .preferredColorScheme(.dark)
}
