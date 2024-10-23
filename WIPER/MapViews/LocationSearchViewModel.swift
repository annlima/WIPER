//
//  LocationSearchViewModel.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 23/10/24.
//

import SwiftUI
import MapKit
import CoreLocation

class LocationSearchViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var mapView = MKMapView()
    @Published var locationManager = CLLocationManager()
    @Published var userLocation: CLLocationCoordinate2D?
    @Published var searchText: String = ""
    
    override init() {
        super.init()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    // Función para buscar y obtener las direcciones
    func searchAndRoute() {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            guard let response = response, let destination = response.mapItems.first else {
                print("No se encontró el lugar o hubo un error: \(error?.localizedDescription ?? "Error desconocido")")
                return
            }
            
            guard let userLocation = self.userLocation else { return }
            
            let sourcePlacemark = MKPlacemark(coordinate: userLocation)
            let destinationPlacemark = destination.placemark
            
            let directionRequest = MKDirections.Request()
            directionRequest.source = MKMapItem(placemark: sourcePlacemark)
            directionRequest.destination = MKMapItem(placemark: destinationPlacemark)
            directionRequest.transportType = .automobile
            
            let directions = MKDirections(request: directionRequest)
            directions.calculate { [weak self] response, error in
                guard let self = self else { return }
                guard let response = response, let route = response.routes.first else {
                    print("No se encontró la ruta o hubo un error: \(error?.localizedDescription ?? "Error desconocido")")
                    return
                }
                
                self.mapView.removeOverlays(self.mapView.overlays)
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
    }
    
    // Actualiza la ubicación del usuario
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        self.userLocation = location.coordinate
    }
}

struct LocationSearchView: View {
    @StateObject private var viewModel = LocationSearchViewModel()

    var body: some View {
        VStack {
            // Barra de búsqueda
            TextField("Buscar lugar", text: $viewModel.searchText, onCommit: {
                viewModel.searchAndRoute()
            })
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding()

            // Vista del mapa
            SearchMapView()
                .environmentObject(viewModel)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct SearchMapView: UIViewRepresentable {
    @EnvironmentObject var viewModel: LocationSearchViewModel

    func makeUIView(context: Context) -> MKMapView {
        viewModel.mapView.delegate = context.coordinator
        return viewModel.mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: SearchMapView

        init(_ parent: SearchMapView) {
            self.parent = parent
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
    }
}
#Preview {
    
}