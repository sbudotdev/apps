import Testing
@testable import SbuPrompter

struct ReadingTimeTests {
    @Test(arguments: [(0, 0), (1, 10), (140, 60), (141, 70), (700, 300)])
    func roundsUpToTenSeconds(words: Int, seconds: Int64) {
        #expect(ReadingTime.duration(words: words) == .seconds(seconds))
    }
}
