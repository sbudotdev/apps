import CoreGraphics
import Foundation

/// Riconosce le finestre scosse, a ogni lettura delle finestre (8 volte al secondo).
/// Con così pochi punti bastano tre cambi di verso, in un tempo più lungo che per il cursore.
nonisolated struct WindowShakes {
    private var detectors: [CGWindowID: ShakeDetector] = [:]

    /// Le finestre attuali; restituisce quelle scosse adesso.
    mutating func update(_ edges: [WindowEdge], at time: TimeInterval) -> Set<CGWindowID> {
        let alive = Set(edges.map(\.id))
        detectors = detectors.filter { alive.contains($0.key) }   // dimentica le finestre chiuse
        var shaken: Set<CGWindowID> = []
        for edge in edges {
            var detector = detectors[edge.id] ?? ShakeDetector(reversals: 3, window: 1.5, minTravel: 40)
            if detector.add(CGPoint(x: edge.rect.midX, y: edge.rect.midY), at: time) { shaken.insert(edge.id) }
            detectors[edge.id] = detector
        }
        return shaken
    }
}
