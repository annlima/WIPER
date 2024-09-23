import SwiftUI
import MapKit
import CoreLocation

struct FavoriteRoute: View {
    @State private var mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 19.03793, longitude: -98.20346), span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
    @State private var searchQuery = ""
    @State private var selectedLocation: Location? = nil
    @State private var route: MKRoute?
    
    @State private var showFavorites = false
    
    // Coordenada actual del usuario (simulada en este caso)
    let userLocation = CLLocationCoordinate2D(latitude: 19.03793, longitude: -98.20346)
    
    struct Location: Identifiable, Equatable {
            let id = UUID()
            let name: String
            let coordinate: CLLocationCoordinate2D
            
            // Implementación de Equatable manualmente
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
                // Mapa de fondo
                Map(coordinateRegion: $mapRegion, annotationItems: locations + (selectedLocation.map { [$0] } ?? [])) { location in
                    MapMarker(coordinate: location.coordinate, tint: location == selectedLocation ? .blue : .red)
                }
                .edgesIgnoringSafeArea(.all)
                
                // Añadir polilínea para la ruta
                if let route = route {
                    Map(coordinateRegion: $mapRegion, annotationItems: locations) { location in
                        MapMarker(coordinate: location.coordinate)
                    }
                    .overlay(
                        MapPolyline(route: route)
                    )
                    .edgesIgnoringSafeArea(.all)
                }
                
                VStack {
                    // Barra de búsqueda y favoritos
                    HStack {
                        TextField("Buscar destino...", text: $searchQuery)
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
                    
                    // Lista de favoritos si está activa
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
            .navigationBarHidden(true) // Ocultamos la barra de navegación para usar nuestro título personalizado
        }
    }
    
    // Seleccionar ubicación y calcular ruta
    func selectLocation(_ location: Location) {
        self.selectedLocation = location
        self.mapRegion.center = location.coordinate
        calculateRoute(to: location.coordinate)
    }
    
    // Función para calcular la ruta entre la ubicación del usuario y el destino
    func calculateRoute(to destination: CLLocationCoordinate2D) {
        let request = MKDirections.Request()
        let sourcePlacemark = MKPlacemark(coordinate: userLocation)
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
struct MapPolyline: View {
    var route: MKRoute
    
    var body: some View {
        Path { path in
            let points = route.polyline.points()
            for i in 0..<route.polyline.pointCount {
                let point = points[i]
                let coordinate = point.coordinate
                let mapPoint = MKMapPoint(coordinate)
                
                if i == 0 {
                    path.move(to: CGPoint(x: mapPoint.x, y: mapPoint.y))
                } else {
                    path.addLine(to: CGPoint(x: mapPoint.x, y: mapPoint.y))
                }
            }
        }
        .stroke(Color.blue, lineWidth: 5)
    }
}

struct FavoriteRoute_Previews: PreviewProvider {
    static var previews: some View {
        FavoriteRoute()
    }
}
