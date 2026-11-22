import Foundation

/// The albums chat apps make in Photos for what they save: WhatsApp, Telegram and the others.
///
/// iOS does not say which app saved a photo; these albums are the one reliable trace. A photo
/// saved by a chat app without its album (Messages, for one) stays with the other photos.
nonisolated enum ChatAlbums {
    /// Album names as the apps write them, compared without case.
    static let names: Set<String> = [
        "whatsapp", "whatsapp business", "telegram", "signal", "messenger", "viber", "wechat", "line", "snapchat", "threema", "kik",
    ]

    /// Whether an album is one a chat app made.
    static func isChatAlbum(_ title: String) -> Bool {
        names.contains(title.trimmingCharacters(in: .whitespaces).lowercased())
    }
}
