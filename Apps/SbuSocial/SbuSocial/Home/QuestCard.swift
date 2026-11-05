import SbuKit
import SwiftUI

/// The Missione del giorno: three tasks, how many are done, and the way into the two you open.
/// The third ticks itself when a block finishes.
struct QuestCard: View {
    let done: Set<QuestTask>
    let open: (QuestTask) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: SbuTheme.space3) {
            Text("Missione del giorno: \(done.count) su \(QuestTask.allCases.count)")
                .font(SbuTheme.footnote)
                .foregroundStyle(SbuTheme.inkMuted)
                .accessibilityAddTraits(.isHeader)
            ProgressView(value: Double(done.count), total: Double(QuestTask.allCases.count))
                .tint(SbuTheme.ink)
                .accessibilityHidden(true)
            SbuListCard(QuestTask.allCases) { task in
                if task == .block {
                    QuestRow(task: task, isDone: done.contains(task))
                } else {
                    Button {
                        open(task)
                    } label: {
                        QuestRow(task: task, isDone: done.contains(task))
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview("Light") {
    QuestCard(done: [.tip]) { _ in }
        .padding()
}

#Preview("Dark") {
    QuestCard(done: []) { _ in }
        .padding()
        .preferredColorScheme(.dark)
}
