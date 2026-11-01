import CoreLocation
import Observation
import SwiftUI

/// One drive: follows the fixes, speaks, and asks for a new route when you leave this one.
@Observable
final class GuidanceModel {
    private(set) var plan: RoutePlan
    private(set) var state = GuidanceState()
    private(set) var status = GuidanceStatus.starting
    var speaks: Bool {
        didSet { if !speaks { voice.stop() } }
    }

    private var tracker: GuidanceTracker
    private let voice = VoiceGuide()
    private let replan: (Point) async throws -> RoutePlan
    private var isRerouting = false
    private var announced: Set<String> = []
    #if DEBUG
    private let trace = TraceRecorder()
    #endif

    init(plan: RoutePlan, speaks: Bool, replan: @escaping (Point) async throws -> RoutePlan) {
        self.plan = plan
        self.speaks = speaks
        self.replan = replan
        tracker = GuidanceTracker(plan: plan)
        state.remainingMetres = plan.metres
        state.remainingSeconds = plan.seconds
    }

    var currentStep: RouteStep? {
        plan.steps.indices.contains(state.stepIndex) ? plan.steps[state.stepIndex] : nil
    }

    /// Runs for the whole drive, with the screen awake and the location in the background.
    func run(location: LocationService) async {
        UIApplication.shared.isIdleTimerDisabled = true
        defer {
            UIApplication.shared.isIdleTimerDisabled = false
            voice.stop()
        }
        let background = CLBackgroundActivitySession()
        defer { background.invalidate() }
        location.start()
        var last: Date?
        while !Task.isCancelled, status != .arrived {
            if let fix = location.fix, fix.date != last {
                last = fix.date
                await receive(fix)
            }
            try? await Task.sleep(for: .milliseconds(300))
        }
    }

    func receive(_ fix: LocationFix) async {
        #if DEBUG
        trace.append(fix)
        #endif
        state = tracker.update(at: fix.point, accuracy: fix.accuracy)
        if state.hasArrived {
            status = .arrived
            say(String(localized: "Sei a destinazione"), once: "arrive")
            return
        }
        if state.isOffRoute, !isRerouting {
            await reroute(from: fix.point)
            return
        }
        status = fix.accuracy > GuidanceTracker.weakAccuracy ? .weakSignal : .following
        announce()
    }

    private func reroute(from point: Point) async {
        isRerouting = true
        status = .rerouting
        defer { isRerouting = false }
        do {
            let fresh = try await replan(point)
            plan = fresh
            tracker = GuidanceTracker(plan: fresh)
            announced = []
            say(String(localized: "Percorso ricalcolato"), once: "reroute\(fresh.metres)")
        } catch {
            // The old route stays on the map: the status line keeps saying it's looking for a new one.
        }
    }

    /// Once far ahead, once at the corner.
    private func announce() {
        guard let step = currentStep, step.maneuver != .arrive || state.metresToManeuver < 300 else { return }
        for threshold in [300.0, 60.0] where state.metresToManeuver <= threshold {
            let metres = max(Int(state.metresToManeuver / 10) * 10, 10)
            say(ManeuverText.spoken(step, metres: metres), once: "\(state.stepIndex)-\(threshold)")
            break
        }
    }

    private func say(_ text: String, once key: String) {
        guard announced.insert(key).inserted, speaks else { return }
        voice.speak(text)
    }
}
