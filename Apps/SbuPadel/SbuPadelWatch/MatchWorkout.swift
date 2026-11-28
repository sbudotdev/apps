import Foundation
import HealthKit
import Observation

/// The match as a workout in Salute, from the first point to the last: like the other padel
/// scorers, it keeps the app in front during play instead of falling back to the watch face, and
/// counts the time, the heart rate and the calories. Apple has no padel type; tennis is the
/// closest racket sport. Nothing leaves the watch but what Salute itself syncs.
@Observable
final class MatchWorkout {
    private let store = HKHealthStore()
    private var session: HKWorkoutSession?
    /// What the match asks for, checked again after the permission prompt.
    private var wanted = false
    private(set) var isRunning = false

    /// Starts the workout; the first time, asks for Salute's permission. Without it the match is
    /// scored the same, only the watch can go back to its face.
    func start() async {
        wanted = true
        guard session == nil, HKHealthStore.isHealthDataAvailable() else { return }
        let energy = HKQuantityType(.activeEnergyBurned)
        do {
            try await store.requestAuthorization(toShare: [HKObjectType.workoutType(), energy], read: [energy, HKQuantityType(.heartRate)])
        } catch {
            return
        }
        guard wanted, session == nil else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .tennis
        configuration.locationType = .unknown
        guard let session = try? HKWorkoutSession(healthStore: store, configuration: configuration) else { return }
        let builder = session.associatedWorkoutBuilder()
        builder.dataSource = HKLiveWorkoutDataSource(healthStore: store, workoutConfiguration: configuration)
        self.session = session
        isRunning = true
        let start = Date.now
        session.startActivity(with: start)
        try? await builder.beginCollection(at: start)
    }

    /// Ends the workout and saves it in Salute; a match undone back to its start within the first
    /// minute is dropped, as it was not played.
    func end() async {
        wanted = false
        guard let session else { return }
        self.session = nil
        isRunning = false
        session.end()
        let builder = session.associatedWorkoutBuilder()
        let ended = Date.now
        try? await builder.endCollection(at: ended)
        if builder.elapsedTime(at: ended) < 60 {
            builder.discardWorkout()
        } else {
            _ = try? await builder.finishWorkout()
        }
    }
}
