import SwiftUI
import MapKit
import Combine

struct FavoriteRoute: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchCompleter = SearchCompleter()

    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 19.03793, longitude: -98.20346), // Puebla Fallback
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedLocation: Location? = nil
    @State private var route: MKRoute?
    @State private var isFollowingUserLocation = true
    @State private var showFavorites = false
    @State private var navigateToCamera = false
    @State private var locations: [Location] = []
    @State private var showingAddToFavorites = false
    @FocusState private var isSearchFocused: Bool
    @State private var didCenterOnInitialUserLocation = false

    struct Location: Identifiable, Equatable, Codable {
        let id: UUID
        let name: String
        let latitude: Double
        let longitude: Double

        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        init(id: UUID = UUID(), name: String, coordinate: CLLocationCoordinate2D) {
            self.id = id
            self.name = name
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
        }

        static func == (lhs: Location, rhs: Location) -> Bool {
            lhs.id == rhs.id
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                CustomMapView(
                    mapRegion: $mapRegion,
                    annotations: annotations,
                    overlays: route != nil ? [route!.polyline] : [],
                    isFollowingUserLocation: $isFollowingUserLocation,
                    locationManager: locationManager,
                    onAnnotationTapped: handleAnnotationTap
                )
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    self.locations = loadLocations()
                    resetMap()
                }
                .onChange(of: locations) {
                    saveLocations()
                }
                .onChange(of: locationManager.currentLocation) { _, newLocation in
                    if !didCenterOnInitialUserLocation, let coordinate = newLocation?.coordinate {
                        setInitialMapRegion(to: coordinate)
                    } else if isFollowingUserLocation, let coordinate = newLocation?.coordinate {
                        mapRegion.center = coordinate
                    }
                    if newLocation != nil {
                        searchCompleter.setRegion(mapRegion)
                    }
                }
                .onTapGesture { isSearchFocused = false }

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ZStack(alignment: .trailing) {
                            TextField("Buscar destino...", text: $searchCompleter.searchQuery)
                                .focused($isSearchFocused)
                                .padding(.trailing, 35)
                                .padding(.vertical, 12)
                                .padding(.leading, 12)
                                .background(Color(.systemBackground))
                                .cornerRadius(10)
                                .shadow(radius: 1)
                                .onSubmit {
                                    searchLocation(query: searchCompleter.searchQuery)
                                    isSearchFocused = false
                                }
                            
                            if !searchCompleter.searchQuery.isEmpty {
                                Button {
                                    searchCompleter.searchQuery = ""
                                    searchCompleter.completions = []
                                    selectedLocation = nil
                                    route = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                                .padding(.trailing, 8)
                            }
                        }
                        
                        Button(action: {
                            self.showFavorites.toggle()
                            isSearchFocused = false
                        }) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.yellow)
                                .padding(8)
                                .background(Color(.systemBackground).opacity(0.8))
                                .clipShape(Circle())
                                .shadow(radius: 3, x: 0, y: 2)
                        }
                        .padding(.leading, 10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 15)
                    
                    if isSearchFocused && !searchCompleter.completions.isEmpty {
                        List(searchCompleter.completions, id: \.self) { completion in
                            VStack(alignment: .leading) {
                                Text(completion.title).font(.headline)
                                Text(completion.subtitle).font(.subheadline).foregroundColor(.gray)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture { handleCompletionTap(completion) }
                        }
                        .listStyle(.plain)
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .frame(maxHeight: 200)
                        .padding(.horizontal)
                        .padding(.top, 5)
                        .shadow(radius: 3)
                        .zIndex(1)
                    }
                    
                    if showFavorites {
                        VStack(spacing: 0) {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(locations) { location in
                                        SwipeToDeleteRow(
                                            location: location,
                                            onDelete: { removeLocation(location) },
                                            onSelect: {
                                                self.selectLocation(location)
                                                self.showFavorites = false
                                                isSearchFocused = false
                                            }
                                        )
                                        Divider()
                                    }
                                }
                            }
                            .frame(maxHeight: itemHeight * 2.8 + 12)
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .padding(.horizontal)
                            .shadow(radius: 3)
                            Spacer()
                        }
                        .padding(.top, 10)
                        .zIndex(1)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Spacer()
                        Button(action: {
                            if self.route != nil {
                                navigateToCamera = true
                                isSearchFocused = false
                            } else {
                                print("Error: No route calculated to start navigation.")
                            }
                        }) {
                            Text("Empezar a viajar")
                                .font(.headline.weight(.semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(selectedLocation != nil && route != nil ? Color.blue : Color.gray)
                                .cornerRadius(10)
                                .shadow(radius: 3)
                        }
                        .disabled(selectedLocation == nil || route == nil)
                        .frame(maxWidth: 400)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 15)
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            recenterMapOnUserLocation()
                            isSearchFocused = false
                        }) {
                            Image(systemName: "location.fill")
                                .font(.system(size: 24))
                                .padding()
                                .background(Color(.systemBackground))
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        .padding(.bottom, 80)
                        .padding(.trailing, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .alert("Agregar a favoritos", isPresented: $showingAddToFavorites, presenting: selectedLocation) { locationToAdd in
                Button("Agregar") { addFavorite(locationToAdd) }
                Button("Cancelar", role: .cancel) {}
            } message: { location in
                Text("¿Deseas agregar \"\(location.name)\" a tus favoritos?")
            }
            .navigationDestination(isPresented: $navigateToCamera) {
                CameraView(calculatedRoute: self.route)
            }
        }
    }

    let itemHeight: CGFloat = 60

    var annotations: [MKAnnotation] {
        var allAnnotations: [MKAnnotation] = locations.map { location in
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotation.title = location.name
            return annotation
        }
        if let selected = selectedLocation, !locations.contains(where: { $0.id == selected.id }) {
            let annotation = MKPointAnnotation()
            annotation.coordinate = selected.coordinate
            annotation.title = selected.name
            allAnnotations.append(annotation)
        }
        return allAnnotations
    }

    // MARK: - Methods
    func handleAnnotationTap(_ annotation: MKAnnotation) {
        guard !(annotation is MKUserLocation) else { return }
        let tappedCoordinate = annotation.coordinate
        
        let nameForLocation: String
        if let titleFromMKAnnotation = annotation.title {
            if !titleFromMKAnnotation!.isEmpty {
                nameForLocation = titleFromMKAnnotation!
            } else {
                nameForLocation = "Ubicación sin nombre (vacío)"
            }
        } else {
            nameForLocation = "Ubicación sin nombre (nil)"
        }

        if let existingFavorite = locations.first(where: { $0.latitude == tappedCoordinate.latitude && $0.longitude == tappedCoordinate.longitude }) {
            selectLocation(existingFavorite)
        } else {
            let tappedLocation = Location(name: nameForLocation, coordinate: tappedCoordinate) // Esto ya no debería dar error
            self.selectedLocation = tappedLocation
            self.showingAddToFavorites = true
        }
        isSearchFocused = false
    }

    func handleCompletionTap(_ completion: MKLocalSearchCompletion) {
        searchCompleter.searchQuery = completion.title
        isSearchFocused = false
        searchCompleter.completions = []
        search(for: completion)
    }

    func search(for suggestedCompletion: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: suggestedCompletion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error detailed search: \(error.localizedDescription)")
                    return
                }
                guard let mapItem = response?.mapItems.first else { return }
                let coordinate = mapItem.placemark.coordinate
                let locationName: String = mapItem.name ?? suggestedCompletion.title
                let newLocation = Location(name: locationName, coordinate: coordinate)
                self.selectLocation(newLocation)
            }
        }
    }

    func searchLocation(query: String) {
        guard !query.isEmpty else { return }
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = query
        searchRequest.region = mapRegion

        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fallback search: \(error.localizedDescription)")
                    return
                }
                guard let mapItem = response?.mapItems.first else { return }
                let coordinate = mapItem.placemark.coordinate
                let locationName: String = mapItem.name ?? query
                let location = Location(name: locationName, coordinate: coordinate)
                self.selectLocation(location)
            }
        }
    }

    func selectLocation(_ location: Location) {
        self.selectedLocation = location
        self.isFollowingUserLocation = false
        self.mapRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        calculateRoute(to: location.coordinate)
        searchCompleter.setRegion(mapRegion)
    }

    func calculateRoute(to destination: CLLocationCoordinate2D) {
        guard let userCoordinate = locationManager.currentLocation?.coordinate else {
            self.route = nil
            return
        }
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userCoordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Route calculation error: \(error.localizedDescription)")
                    self.route = nil
                    return
                }
                self.route = response?.routes.first
                if let route = self.route {
                    self.mapRegion = MKCoordinateRegion(route.polyline.boundingMapRect.insetBy(dx: -3000, dy: -3000))
                    self.isFollowingUserLocation = false
                } else {
                    self.route = nil
                }
            }
        }
    }
    
    func handleLocationChange(_ newLocation: EquatableLocation?) {
        if newLocation != nil {
             searchCompleter.setRegion(mapRegion)
        }
    }
    
    func setInitialMapRegion(to coordinate: CLLocationCoordinate2D) {
        mapRegion = MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        isFollowingUserLocation = true
        didCenterOnInitialUserLocation = true
        searchCompleter.setRegion(mapRegion)
    }

    func recenterMapOnUserLocation() {
        if let userCoordinate = locationManager.currentLocation?.coordinate {
            mapRegion = MKCoordinateRegion(
                center: userCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
            isFollowingUserLocation = true
            didCenterOnInitialUserLocation = true
            searchCompleter.setRegion(mapRegion)
        }
    }

    func addFavorite(_ locationToAdd: Location) {
         if !locations.contains(where: { $0.latitude == locationToAdd.latitude && $0.longitude == locationToAdd.longitude }) {
             locations.append(locationToAdd)
         }
    }

    func removeLocation(_ location: Location) {
        locations.removeAll { $0.id == location.id }
        if selectedLocation?.id == location.id {
            selectedLocation = nil
            route = nil
        }
    }

    func resetMap() {
        selectedLocation = nil
        route = nil
        
        if let userCoordinate = locationManager.currentLocation?.coordinate {
            let span = didCenterOnInitialUserLocation ? mapRegion.span : MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            mapRegion = MKCoordinateRegion(center: userCoordinate, span: span)
            isFollowingUserLocation = true
            didCenterOnInitialUserLocation = true
            searchCompleter.setRegion(mapRegion)
        } else {
            isFollowingUserLocation = true
            didCenterOnInitialUserLocation = false
        }
        
        searchCompleter.searchQuery = ""
        searchCompleter.completions = []
        isSearchFocused = false
        showFavorites = false
    }

    private func getLocationsFileURL() -> URL {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Unable to access Documents directory.")
        }
        return documentsDirectory.appendingPathComponent("favoriteLocations.json")
    }

    private func loadLocations() -> [Location] {
        let fileURL = getLocationsFileURL()
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
             return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let loadedLocations = try decoder.decode([Location].self, from: data)
            return loadedLocations
        } catch {
            print("Failed to load locations: \(error)")
            return []
        }
    }

    private func saveLocations() {
        let fileURL = getLocationsFileURL()
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(locations)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            print("Failed to save locations: \(error)")
        }
    }
}
