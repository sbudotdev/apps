import MapKit
import SbuKit
import SwiftUI

/// The full-screen map: zones colored by the answer for this vehicle at this moment (ADR-0020).
struct ZoneMapView: View {
    @Bindable var model: MapModel
    let route: RoutePlan?
    let marker: Place?
    @State private var visibleRegion: MKCoordinateRegion?

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

    private var parkings: [Parking] {
        guard model.store.state.showsParking, let region = visibleRegion else { return [] }
        return ParkingCatalog.bundled.visible(latitude: region.center.latitude, longitude: region.center.longitude,
                                              latitudeDelta: region.span.latitudeDelta, longitudeDelta: region.span.longitudeDelta)
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
                ForEach(parkings) { parking in
                    Annotation(parking.name, coordinate: parking.point.coordinate) {
                        ParkingMark(name: parking.name)
                    }
                    .annotationTitles(.hidden)
                }
                UserAnnotation()
            }
            .mapStyle(.standard(elevation: model.store.state.shows3D ? .realistic : .flat, pointsOfInterest: .excluding([.parking])))
            .mapControls {}
            .onMapCameraChange(frequency: .onEnd) { visibleRegion = $0.region }
            .onTapGesture { position in
                if let coordinate = proxy.convert(position, from: .local) {
                    model.selectPoint(Point(coordinate))
                }
            }
        }
    }
}
