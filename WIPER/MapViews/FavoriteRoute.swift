import SwiftUI
import MapKit

struct FavoriteRoute: View {
    @StateObject private var locationManager = LocationManager()
        @State private var mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 19.03793, longitude: -98.20346),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        @State private var searchQuery = ""
        @State private var selectedLocation: Location? = nil
        @State private var route: MKRoute?
        @State private var isFollowingUserLocation = true
        @State private var showFavorites = false
        @State private var navigateToCamera = false
        @State private var locations = [
            Location(name: "Catedral", coordinate: CLLocationCoordinate2D(latitude: 19.04281015, longitude: -98.1983963)),
            Location(name: "Zócalo", coordinate: CLLocationCoordinate2D(latitude: 19.0438393, longitude: -98.1982317)),
            Location(name: "Pirámide de Cholula", coordinate: CLLocationCoordinate2D(latitude: 19.0579573, longitude: -98.3022263468972))
        ]
        @State private var showingAddToFavorites = false

    struct Location: Identifiable, Equatable {
        let id = UUID()
        let name: String
        let coordinate: CLLocationCoordinate2D

        static func == (lhs: Location, rhs: Location) -> Bool {
            return lhs.name == rhs.name &&
                   lhs.coordinate.latitude == rhs.coordinate.latitude &&
                   lhs.coordinate.longitude == rhs.coordinate.longitude
        }
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Mapa personalizado
                CustomMapView(
                    mapRegion: $mapRegion,
                    annotations: annotations,
                    overlays: route != nil ? [route!.polyline] : [],
                    isFollowingUserLocation: $isFollowingUserLocation,
                    locationManager: locationManager,
                    onAnnotationTapped: { location in
                        if !locations.contains(where: {
                            $0.coordinate.latitude == location.coordinate.latitude &&
                            $0.coordinate.longitude == location.coordinate.longitude
                        }) {
                            let title = (location.title ?? nil) ?? "Destino"
                            selectedLocation = Location(name: title, coordinate: location.coordinate)
                            showingAddToFavorites = true
                        }
                    }
                )
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    resetMap() // Llama a la función para limpiar el mapa al aparecer
                }
                .onChange(of: locationManager.currentLocation) { newLocation in
                    if let newLocation = newLocation, isFollowingUserLocation {
                        mapRegion = MKCoordinateRegion(
                            center: newLocation.coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                        )
                    }
                }

                VStack(spacing: 0) {
                    // Barra de búsqueda y botones
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

                    // Vista de favoritos debajo de la barra de búsqueda
                    if showFavorites {
                        VStack(spacing: 0) {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(locations) { location in
                                        SwipeToDeleteRow(
                                            location: location,
                                            onDelete: {
                                                removeLocation(location)
                                            },
                                            onSelect: {
                                                self.selectLocation(location)
                                                self.showFavorites = false // Cierra favoritos después de seleccionar
                                            }
                                        )
                                        Divider()
                                    }
                                }
                            }
                            .frame(maxHeight: itemHeight * 2.8 + 12) // Mostrar hasta 3 elementos
                            .background(Color.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                            Spacer()
                        }
                        .padding(.top, 10)
                    }

                    Spacer()

                    // Botón de navegación a la vista de la cámara
                    if selectedLocation != nil {
                        NavigationLink(destination: CameraView(), isActive: $navigateToCamera) {
                            Button(action: {
                                navigateToCamera = true
                            }) {
                                Text("Empezar a viajar")
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
                            Text("Empezar a viajar")
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

                // Botón para recentralizar en la ubicación del usuario
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
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
                        .padding(.bottom, 75)
                        .padding(.trailing, 35)
                    }
                }
            }
            .navigationBarHidden(true)
            .alert(isPresented: $showingAddToFavorites) {
                Alert(
                    title: Text("Agregar a favoritos"),
                    message: Text("¿Deseas agregar esta ubicación a tus favoritos?"),
                    primaryButton: .default(Text("Agregar")) {
                        if let selectedLocation = selectedLocation {
                            locations.append(selectedLocation)
                        }
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .navigationBarHidden(true)
    }

    let itemHeight: CGFloat = 60 // Altura estándar de un elemento de lista

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
        self.mapRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
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
                self.mapRegion = MKCoordinateRegion(route.polyline.boundingMapRect)
                self.isFollowingUserLocation = false
            } else {
                print("Error al calcular la ruta: \(error?.localizedDescription ?? "Desconocido")")
            }
        }
    }

    func recenterMapOnUserLocation() {
        if let userLocation = locationManager.currentLocation {
            mapRegion = MKCoordinateRegion(
                center: userLocation.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            isFollowingUserLocation = true
        }
    }

    func removeLocation(_ location: Location) {
        if let index = locations.firstIndex(of: location) {
            locations.remove(at: index)
        }
    }
    
    func resetMap() {
        selectedLocation = nil
        route = nil
        isFollowingUserLocation = true
    }
}
