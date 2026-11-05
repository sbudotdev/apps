import SbuKit
import SwiftUI

/// The tool screen: Blocca ora and the Intenzioni.
struct HomeView: View {
    @Environment(ShieldModel.self) private var shield

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SbuTheme.space6) {
                SbuScreenTitle("Home", cartiglio: Cartiglio.today)
                BlockNowCard(shield: shield)
            }
            .padding(SbuTheme.space4)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .sbuPaper(grid: true)
    }
}

#Preview("Light") {
    NavigationStack {
        HomeView()
    }
    .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!))
}

#Preview("Dark") {
    NavigationStack {
        HomeView()
    }
    .environment(ShieldModel(defaults: UserDefaults(suiteName: "preview")!))
    .preferredColorScheme(.dark)
}
