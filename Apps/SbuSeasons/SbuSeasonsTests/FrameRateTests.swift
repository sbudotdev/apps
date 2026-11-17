import Testing
@testable import SbuSeasons

@Test(arguments: [
    (onBattery: false, reduceMotion: false, fps: 60),
    (onBattery: true, reduceMotion: false, fps: 30),
    (onBattery: false, reduceMotion: true, fps: 30),
])
func snowRunsAt30FramesPerSecondOnBatteryOrWithReduceMotion(onBattery: Bool, reduceMotion: Bool, fps: Int) {
    #expect(Tuning.framesPerSecond(onBattery: onBattery, reduceMotion: reduceMotion) == fps)
}
