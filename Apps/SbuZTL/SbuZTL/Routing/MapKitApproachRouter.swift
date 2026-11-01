import MapKit

/// The stretch from outside the graph, from Apple's directions (ADR-0019).
nonisolated struct MapKitApproachRouter: ApproachRouter {
    func leg(from start: Point, to end: Point) async throws -> ApproachLeg {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: start.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: end.coordinate))
        request.transportType = .automobile
        let response = try await MKDirections(request: request).calculate()
        guard let route = response.routes.first else { throw RouteError.noRoute }
        var coordinates = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: route.polyline.pointCount)
        route.polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: route.polyline.pointCount))
        var run = 0.0
        var steps: [ApproachStep] = []
        for step in route.steps {
            if !step.instructions.isEmpty {
                steps.append(ApproachStep(instruction: step.instructions, startMetre: run))
            }
            run += step.distance
        }
        return ApproachLeg(points: coordinates.map(Point.init), seconds: route.expectedTravelTime, steps: steps)
    }
}
