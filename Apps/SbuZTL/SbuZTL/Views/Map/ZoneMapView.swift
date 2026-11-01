import MapKit
import SbuKit
import SwiftUI

/// The full-screen map: zones colored by the answer for this vehicle at this moment (ADR-0020).
struct ZoneMapView: View {
    @Bindable var model: MapModel
    let route: RoutePlan?
    let marker: Place?

    private struct Overlay: Identifiable {
        let id: String
        let coordinates: [CLLocationCoordinate2D]
        let access: Access
    }

    private var overlays: [Overlay] {
        guard model.showsZones else { return [] }
        let vehicle = model.store.vehicle, moment = model.moment, permits = model.store.state.permits
        return model.catalog.zones.flatMap { zone in
            let access = RuleEngine.verdict(zone: zone, vehicle: vehicle, at: moment, permits: permits).access
            return zone.polygons.enumerated().map { index, polygon in
                Overlay(id: "\(zone.id)-\(index)", coordinates: polygon.ring.map(\.coordinate), access: access)
            }
        }
    }

    var body: some View {
        MapReader { proxy in
            Map(position: $model.camera) {
                ForEach(overlays) { overlay in
                    MapPolygon(coordinates: overlay.coordinates)
                        .foregroundStyle(overlay.access.tint.opacity(0.18))
                        .stroke(overlay.access.tint, lineWidth: 1)
                }
                if let route {
                    MapPolyline(coordinates: route.points.map(\.coordinate))
                        .stroke(SbuTheme.ink, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                }
                if let marker {
                    Marker(marker.name, coordinate: marker.point.coordinate)
                        .tint(SbuTheme.ink)
                }
                UserAnnotation()
            }
            .mapStyle(.standard(elevation: model.store.state.shows3D ? .realistic : .flat,
                                pointsOfInterest: model.store.state.showsParking ? .all : .excluding([.parking])))
            .mapControls {}
            .onTapGesture { position in
                if let coordinate = proxy.convert(position, from: .local) {
                    model.selectPoint(Point(coordinate))
                }
            }
        }
    }
}
