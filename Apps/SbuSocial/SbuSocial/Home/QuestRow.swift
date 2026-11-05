import SbuKit
import SwiftUI

/// One task of the Missione del giorno: its mark, its name, and whether it is done.
struct QuestRow: View {
    let task: QuestTask
    let isDone: Bool

    var body: some View {
        HStack(spacing: SbuTheme.space3) {
            SbuRowMark(filled: isDone)
            Text(task.title)
            Spacer()
            (isDone ? Text("Fatto") : Text("Da fare"))
                .foregroundStyle(SbuTheme.inkMuted)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    QuestRow(task: .tip, isDone: true)
        .padding()
}

#Preview("Dark") {
    QuestRow(task: .block, isDone: false)
        .padding()
        .preferredColorScheme(.dark)
}
