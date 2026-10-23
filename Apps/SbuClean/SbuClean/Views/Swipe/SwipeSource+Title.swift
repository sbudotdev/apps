import SwiftUI

extension SwipeSource {
    /// The navigation title of the queue.
    var title: Text {
        switch self {
        case .recent: Text("Recenti")
        case .random: Text("Casuale")
        case .onThisDay: Text("Accadde oggi")
        case .onDay(let day): Text(day.date(in: 2000) ?? .now, format: .dateTime.day().month(.wide))
        case .later: Text("Da decidere dopo")
        case .month(let month): Text(month.firstDay(in: .current), format: .dateTime.month(.wide).year())
        case .album(let album): Text(verbatim: album.title)
        case .category(let category): category.title
        }
    }
}

extension MediaCategory {
    var title: Text {
        switch self {
        case .screenshots: Text("Screenshot")
        case .screenRecordings: Text("Registrazioni")
        case .videos: Text("Video")
        case .livePhotos: Text("Live Photo")
        case .chats: Text("Foto dalle chat")
        case .blurry: Text("Foto sfocate")
        }
    }
}

extension MediaCategory {
    /// What the grid says when the category is empty.
    var emptySentence: LocalizedStringKey {
        switch self {
        case .screenshots: "Nessuno screenshot nella libreria."
        case .screenRecordings: "Nessuna registrazione dello schermo nella libreria."
        case .videos: "Nessun video nella libreria."
        case .livePhotos: "Nessuna Live Photo nella libreria."
        case .chats: "Nessuna foto salvata dalle chat. Le trovi qui se WhatsApp, Telegram o un'altra app le salva nel suo album."
        case .blurry: "Nessuna foto sfocata trovata."
        }
    }
}
