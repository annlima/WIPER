import SwiftUI
import MapKit

struct FavoriteRoute: View {
    @StateObject private var locationManager = LocationManager()
    @State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 19.03793, longitude: -98.20346), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @State private var searchQuery = ""
    @State private var selectedLocation: Location? = nil
    @State private var route: MKRoute?
    @State private var isFollowingUserLocation = true
    @State private var showFavorites = false
    
    struct Location: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D
        
        static func == (lhs: Location, rhs: Location) -> Bool {
            return lhs.name == rhs.name && lhs.coordinate.latitude == rhs.coordinate.latitude && lhs.coordinate.longitude == rhs.coordinate.longitude
        }
    }
    
    // Lugares favoritos
    let locations = [
        Location(name: "Catedral", coordinate: CLLocationCoordinate2D(latitude: 19.04281015, longitude: -98.1983963)),
        Location(name: "Zócalo", coordinate: CLLocationCoordinate2D(latitude: 19.0438393, longitude: -98.1982317)),
        Location(name: "Pirámide de Cholula", coordinate: CLLocationCoordinate2D(latitude: 19.0579573, longitude: -98.3022263468972))
    ]
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Map(coordinateRegion: $mapRegion, interactionModes: [.all], showsUserLocation: true, annotationItems: locations + (selectedLocation.map { [$0] } ?? [])) { location in
                    MapMarker(coordinate: location.coordinate, tint: location == selectedLocation ? .blue : .red)
                }
                .edgesIgnoringSafeArea(.all)
                .onChange(of: locationManager.currentLocation) { newLocation in
                    if let newLocation = newLocation, isFollowingUserLocation {
                        mapRegion = MKCoordinateRegion(center: newLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                    }
                }
                .onAppear {
                    if let userLocation = locationManager.currentLocation {
                        mapRegion.center = userLocation.coordinate
                    }
                }
                
                if let route = route {
                    RouteOverlay(route: route)
                        .edgesIgnoringSafeArea(.all)
                }
                
                VStack {
                    // Barra de búsqueda y favoritos
                    HStack {
                        TextField("Buscar destino...", text: $searchQuery, onCommit: {
                            searchLocation()
                        })
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        
                        Button(action: {
                            self.showFavorites.toggle()
                        }) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.yellow)
                        }
                        .padding(.trailing, 16)
                    }
                    .padding(.top, 10)
                    
                    if showFavorites {
                        ScrollView {
                            VStack(alignment: .leading) {
                                ForEach(locations) { location in
                                    Button(action: {
                                        self.selectLocation(location)
                                    }) {
                                        Text(location.name)
                                            .padding()
                                            .background(Color.white)
                                            .cornerRadius(10)
                                            .padding(.horizontal)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    func searchLocation() {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchQuery
        
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            if let response = response, let mapItem = response.mapItems.first {
                let coordinate = mapItem.placemark.coordinate
                let location = Location(name: mapItem.name ?? "Destino", coordinate: coordinate)
                self.selectLocation(location)
            } else {
                print("Error al buscar la ubicación: \(error?.localizedDescription ?? "Desconocido")")
            }
        }
    }
    
    func selectLocation(_ location: Location) {
        self.selectedLocation = location
        self.isFollowingUserLocation = false
        self.mapRegion.center = location.coordinate
        calculateRoute(to: location.coordinate)
    }
    
    func calculateRoute(to destination: CLLocationCoordinate2D) {
        guard let userLocation = locationManager.currentLocation else {
            print("No se pudo obtener la ubicación actual")
            return
        }
        
        let request = MKDirections.Request()
        let sourcePlacemark = MKPlacemark(coordinate: userLocation.coordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destination)
        
        request.source = MKMapItem(placemark: sourcePlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        request.transportType = .automobile
        
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let response = response, let route = response.routes.first {
                self.route = route
            } else {
                print("Error al calcular la ruta: \(error?.localizedDescription ?? "Desconocido")")
            }
        }
    }
}

// Vista para dibujar la polilínea de la ruta en el mapa
struct RouteOverlay: UIViewRepresentable {
    var route: MKRoute
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.addOverlay(route.polyline)
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        uiView.addOverlay(route.polyline)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RouteOverlay
        
        init(_ parent: RouteOverlay) {
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
