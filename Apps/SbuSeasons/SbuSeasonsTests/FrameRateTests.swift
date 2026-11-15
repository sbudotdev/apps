import Testing
@testable import CozySnow

@Test(arguments: [(onBattery: false, fps: 60), (onBattery: true, fps: 30)])
func snowRunsAt30FramesPerSecondOnBattery(onBattery: Bool, fps: Int) {
    #expect(Tuning.framesPerSecond(onBattery: onBattery) == fps)
}
