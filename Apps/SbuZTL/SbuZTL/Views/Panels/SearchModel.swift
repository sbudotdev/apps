import MapKit
import Observation

/// Place search through Apple's Maps (ADR-0019).
@Observable
final class SearchModel {
    var query = ""
    private(set) var results: [Place] = []
    private(set) var isSearching = false

    /// Debounced by the view's `.task(id:)`: a new query cancels this one.
    func search(near point: Point?) async {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard text.count >= 2 else {
            results = []
            isSearching = false
            return
        }
        isSearching = true
        defer { isSearching = false }
        do {
            try await Task.sleep(for: .milliseconds(300))
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = text
            request.region = MKCoordinateRegion(center: (point ?? Point(42.5, 12.5)).coordinate,
                                                latitudinalMeters: point == nil ? 1_200_000 : 40_000,
                                                longitudinalMeters: point == nil ? 1_200_000 : 40_000)
            let response = try await MKLocalSearch(request: request).start()
            try Task.checkCancellation()
            results = response.mapItems.prefix(15).map { item in
                Place(name: item.name ?? text, address: item.placemark.title ?? "", point: Point(item.placemark.coordinate),
                      symbol: Self.symbol(item.pointOfInterestCategory))
            }
        } catch is CancellationError {
            return
        } catch {
            results = []
        }
    }

    private static func symbol(_ category: MKPointOfInterestCategory?) -> String {
        switch category {
        case .restaurant, .cafe: "fork.knife"
        case .hotel: "bed.double"
        case .parking: "parkingsign"
        case .museum: "building.columns"
        case .hospital: "cross"
        case .publicTransport: "tram"
        default: "mappin"
        }
    }
}
