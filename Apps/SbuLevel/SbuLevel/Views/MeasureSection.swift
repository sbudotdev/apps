import SbuKit
import SwiftUI

struct MeasureSection: View {
    @Bindable var model: LevelModel

    var body: some View {
        Section {
            Toggle("Schermo sempre acceso", isOn: $model.keepsScreenAwake)
        } header: {
            Text("Durante la misura")
        } footer: {
            Text("Lo schermo non si spegne mentre l'app è aperta.")
        }
    }
}

#Preview("Light") {
    List {
        MeasureSection(model: LevelModel(source: FixedGravitySource.screenshot))
    }
}

#Preview("Dark") {
    List {
        MeasureSection(model: LevelModel(source: FixedGravitySource.screenshot))
    }
    .preferredColorScheme(.dark)
}
