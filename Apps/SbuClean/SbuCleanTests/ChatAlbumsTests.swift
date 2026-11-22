import Testing
@testable import SbuClean

struct ChatAlbumsTests {
    @Test(arguments: ["WhatsApp", "Telegram", " whatsapp ", "LINE", "WhatsApp Business"])
    func chatAppAlbums(_ title: String) {
        #expect(ChatAlbums.isChatAlbum(title))
    }

    @Test(arguments: ["Vacanze", "Online", "WhatsApp vecchie", "", "Messaggi"])
    func otherAlbums(_ title: String) {
        #expect(!ChatAlbums.isChatAlbum(title))
    }
}
