import SbuKit
import SwiftUI

/// Screenshots, screen recordings, chat photos or blurry photos in a grid, biggest first: select them, or swipe through
/// them, and send them to the bin.
struct MediaGridScreen: View {
    let model: CleanModel
    let category: MediaCategory

    @State private var selection: Set<String> = []
    @State private var showsBin = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: SbuTheme.space1)]

    var body: some View {
        let items = model.items(in: category).filter { !model.state.trash.contains($0.id) }
        let bytes = model.bytes(of: selection)
        Group {
            if items.isEmpty {
                EmptyScreen(sentence: category.emptySentence)
            } else {
                grid(items, bytes: bytes)
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showsBin) {
            BinScreen(model: model)
        }
    }

    private func grid(_ items: [MediaItem], bytes: Int64) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: SbuTheme.space4) {
                SpaceStat(label: "Selezionati", bytes: bytes, context: "\(selection.count) di \(items.count)")

                // In the content, not in the bar: on a small iPhone the bar button cut the title.
                // Not ViewThatFits: its hidden layout stayed in the accessibility tree, and a tap
                // on it landed on a photo.
                let layout = dynamicTypeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: SbuTheme.space2))
                    : AnyLayout(HStackLayout(spacing: SbuTheme.space2))
                layout {
                    actions(items)
                }
                .buttonStyle(SbuFieldPillStyle())

                LazyVGrid(columns: columns, spacing: SbuTheme.space1) {
                    ForEach(items) { item in
                        MediaGridTile(item: item, isSelected: selection.contains(item.id)) {
                            toggle(item.id)
                        }
                    }
                }
            }
            .padding(SbuTheme.space4)
        }
        .background(SbuTheme.paper)
        .bottomAction {
            SbuButton(DeleteTitle.forBytes(bytes)) {
                model.moveToTrash(items.map(\.id).filter(selection.contains))
                selection = []
                showsBin = true
            }
            .disabled(selection.isEmpty)
            .accessibilityIdentifier("bottomAction")
        }
    }

    @ViewBuilder
    private func actions(_ items: [MediaItem]) -> some View {
        NavigationLink("Scorri uno per uno", value: Route.swipe(.category(category)))
        Button(selection.count == items.count ? "Deseleziona tutto" : "Seleziona tutto") {
            selection = selection.count == items.count ? [] : Set(items.map(\.id))
        }
    }

    private func toggle(_ id: String) {
        if selection.contains(id) {
            selection.remove(id)
        } else {
            selection.insert(id)
        }
    }
}

#Preview("Light") {
    MediaGridPreview()
}

#Preview("Dark") {
    MediaGridPreview()
        .preferredColorScheme(.dark)
}

private struct MediaGridPreview: View {
    @State private var model = CleanModel.preview

    var body: some View {
        NavigationStack {
            MediaGridScreen(model: model, category: .screenshots)
        }
        .environment(\.sbuAccent, .clean)
        .task {
            await model.reload()
        }
    }
}
