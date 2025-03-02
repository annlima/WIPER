//
//  CustomMapView.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 10/11/24.
//
import SwiftUI
import MapKit


struct CustomMapView: UIViewRepresentable {
    @Binding var mapRegion: MKCoordinateRegion
    var annotations: [MKAnnotation]
    var overlays: [MKOverlay]
    @Binding var isFollowingUserLocation: Bool
    @ObservedObject var locationManager: LocationManager
    var onAnnotationTapped: ((MKAnnotation) -> Void)? = nil

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.setRegion(mapRegion, animated: false)
        mapView.addAnnotations(annotations)
        mapView.addOverlays(overlays)
        mapView.userTrackingMode = isFollowingUserLocation ? .follow : .none
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        if isFollowingUserLocation {
            mapView.setRegion(mapRegion, animated: true)
            mapView.userTrackingMode = .follow
        } else {
            mapView.userTrackingMode = .none
        }

        updateAnnotations(mapView)

        updateOverlays(mapView)
    }

    func updateAnnotations(_ mapView: MKMapView) {
        let existingAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        let newAnnotations = annotations

        // Anotaciones a remover
        let annotationsToRemove = existingAnnotations.filter { existing in
            !newAnnotations.contains { newAnnotation in
                newAnnotation.coordinate.latitude == existing.coordinate.latitude &&
                newAnnotation.coordinate.longitude == existing.coordinate.longitude
            }
        }

        // Anotaciones a agregar
        let annotationsToAdd = newAnnotations.filter { newAnnotation in
            !existingAnnotations.contains { existing in
                existing.coordinate.latitude == newAnnotation.coordinate.latitude &&
                existing.coordinate.longitude == newAnnotation.coordinate.longitude
            }
        }

        if !annotationsToRemove.isEmpty {
            mapView.removeAnnotations(annotationsToRemove)
        }

        if !annotationsToAdd.isEmpty {
            mapView.addAnnotations(annotationsToAdd)
        }
    }

    func updateOverlays(_ mapView: MKMapView) {
        let existingOverlays = mapView.overlays
        let newOverlays = overlays

        let overlaysToRemove = existingOverlays.filter { existing in
            !newOverlays.contains { newOverlay in
                existing === newOverlay
            }
        }

        let overlaysToAdd = newOverlays.filter { newOverlay in
            !existingOverlays.contains { existing in
                existing === newOverlay
            }
        }

        if !overlaysToRemove.isEmpty {
            mapView.removeOverlays(overlaysToRemove)
        }

        if !overlaysToAdd.isEmpty {
            mapView.addOverlays(overlaysToAdd)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self, isFollowingUserLocation: $isFollowingUserLocation)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: CustomMapView
        @Binding var isFollowingUserLocation: Bool

        init(_ parent: CustomMapView, isFollowingUserLocation: Binding<Bool>) {
            self.parent = parent
            self._isFollowingUserLocation = isFollowingUserLocation
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            if mapView.isUserInteractionEnabled {
                isFollowingUserLocation = false
            }
            parent.mapRegion = mapView.region
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 5
                return renderer
            }
            return MKOverlayRenderer()
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation {
                parent.onAnnotationTapped?(annotation)
            }
        }
    }
}
