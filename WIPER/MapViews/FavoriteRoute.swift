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
    @State private var navigateToCamera = false

    struct Location: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D

        static func == (lhs: Location, rhs: Location) -> Bool {
            return lhs.name == rhs.name && lhs.coordinate.latitude == rhs.coordinate.latitude && lhs.coordinate.longitude == rhs.coordinate.longitude
        }
    }

    let locations = [
        Location(name: "Catedral", coordinate: CLLocationCoordinate2D(latitude: 19.04281015, longitude: -98.1983963)),
        Location(name: "Zócalo", coordinate: CLLocationCoordinate2D(latitude: 19.0438393, longitude: -98.1982317)),
        Location(name: "Pirámide de Cholula", coordinate: CLLocationCoordinate2D(latitude: 19.0579573, longitude: -98.3022263468972))
    ]

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                CustomMapView(
                    mapRegion: $mapRegion,
                    annotations: annotations,
                    overlays: route != nil ? [route!.polyline] : [],
                    isFollowingUserLocation: $isFollowingUserLocation,
                    locationManager: locationManager
                )
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    if let userLocation = locationManager.currentLocation {
                        mapRegion = MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                    }
                }
                .onChange(of: locationManager.currentLocation) { newLocation in
                    if let newLocation = newLocation, isFollowingUserLocation {
                        mapRegion = MKCoordinateRegion(center: newLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
                    }
                }

                VStack {
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

                    // Botón para recentralizar en la ubicación del usuario
                    Button(action: {
                        recenterMapOnUserLocation()
                    }) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 24))
                            .padding()
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(radius: 5)
                    }
                    .padding(.bottom, 10)

                    // Botón de navegación a la vista de la cámara
                    if selectedLocation != nil {
                        NavigationLink(destination: CameraView(), isActive: $navigateToCamera) {
                            Button(action: {
                                navigateToCamera = true
                            }) {
                                Text("Ir a la cámara")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 10)
                        }
                    } else {
                        Button(action: {}) {
                            Text("Ir a la cámara")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray)
                                .cornerRadius(10)
                        }
                        .disabled(true)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .navigationBarHidden(true)
    }

    var annotations: [MKAnnotation] {
        var allAnnotations: [MKAnnotation] = locations.map { location in
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotation.title = location.name
            return annotation
        }
        if let selectedLocation = selectedLocation {
            let annotation = MKPointAnnotation()
            annotation.coordinate = selectedLocation.coordinate
            annotation.title = selectedLocation.name
            allAnnotations.append(annotation)
        }
        return allAnnotations
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
        self.mapRegion = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
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
                // Ajustar la región del mapa para mostrar la ruta completa
                self.mapRegion = MKCoordinateRegion(route.polyline.boundingMapRect)
                self.isFollowingUserLocation = false
            } else {
                print("Error al calcular la ruta: \(error?.localizedDescription ?? "Desconocido")")
            }
        }
    }

    func recenterMapOnUserLocation() {
        if let userLocation = locationManager.currentLocation {
            mapRegion = MKCoordinateRegion(center: userLocation.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
            isFollowingUserLocation = true
        }
    }
}

struct CustomMapView: UIViewRepresentable {
    @Binding var mapRegion: MKCoordinateRegion
    var annotations: [MKAnnotation]
    var overlays: [MKOverlay]
    @Binding var isFollowingUserLocation: Bool
    @ObservedObject var locationManager: LocationManager

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
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(annotations)
        mapView.removeOverlays(mapView.overlays)
        mapView.addOverlays(overlays)
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
            // Si el usuario mueve el mapa, detenemos el recentrado automático
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
    }
}
