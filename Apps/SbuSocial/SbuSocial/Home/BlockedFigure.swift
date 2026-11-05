import SbuKit
import SwiftUI

/// Home's figure: the time in a block today, ticking while a block runs, with the best day's.
struct BlockedFigure: View {
    let tally: Tally
    let isBlocking: Bool

    var body: some View {
        // Every second only while a block runs: at rest the figure does not change.
        TimelineView(.periodic(from: .now, by: isBlocking ? 1 : 3600)) { timeline in
            let blocked = tally.blocked(now: timeline.date)
            SbuFigure(value: Duration.seconds(blocked.rounded(.down)).formatted(.time(pattern: .hourMinuteSecond)),
                      fullStop: isBlocking ? .set : .waiting,
                      context: context(record: max(tally.record, blocked)),
                      accessibilityLabel: Text("\(Self.spoken(blocked)) in blocco oggi"))
        }
    }

    private func context(record: TimeInterval) -> Text {
        record >= 60 ? Text("in blocco oggi, record \(Self.spoken(record))") : Text("in blocco oggi")
    }

    private static func spoken(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds.rounded(.down)).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}

#Preview("Light") {
    BlockedFigure(tally: Tally.sample(), isBlocking: true)
        .padding()
}

#Preview("Dark") {
    BlockedFigure(tally: Tally(), isBlocking: false)
        .padding()
        .preferredColorScheme(.dark)
}
