import Testing
@testable import SbuPrompter

struct CountdownTests {
    @Test func offersTheFourChoices() {
        #expect(Countdown.choices == [0, 3, 5, 10])
    }

    @Test(arguments: [
        (3, 0.0, 3), (3, 0.2, 3), (3, 1.0, 2), (3, 2.5, 1), (10, 9.99, 1),
    ])
    func showsWholeSecondsLeft(seconds: Int, elapsed: Double, expected: Int) {
        #expect(Countdown(seconds: seconds).remaining(after: elapsed) == expected)
    }

    @Test(arguments: [(3, 3.0), (3, 4.0), (0, 0.0)])
    func isOverAtTheEnd(seconds: Int, elapsed: Double) {
        #expect(Countdown(seconds: seconds).remaining(after: elapsed) == nil)
    }
}
