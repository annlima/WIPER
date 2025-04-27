import SwiftUI
import MapKit // Make sure MapKit is imported
import Combine // Needed for SearchCompleter

// MARK: - FavoriteRoute View Definition
struct FavoriteRoute: View {
    // Use StateObject for managers owned by this view
    @StateObject private var locationManager = LocationManager()
    @StateObject private var searchCompleter = SearchCompleter()

    // Map and UI State
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 19.03793, longitude: -98.20346), // Puebla Center approx.
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    @State private var selectedLocation: Location? = nil
    @State private var route: MKRoute?
    @State private var isFollowingUserLocation = true
    @State private var showFavorites = false
    @State private var navigateToCamera = false
    @State private var locations: [Location] = [] // Loaded in .onAppear
    @State private var showingAddToFavorites = false
    @FocusState private var isSearchFocused: Bool

    // MARK: - Location Struct (Codable)
    struct Location: Identifiable, Equatable, Codable {
        let id: UUID
        let name: String
        let latitude: Double
        let longitude: Double

        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }

        // Initializer taking CLLocationCoordinate2D
        init(id: UUID = UUID(), name: String, coordinate: CLLocationCoordinate2D) {
            self.id = id
            self.name = name
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
        }

        static func == (lhs: Location, rhs: Location) -> Bool {
            lhs.id == rhs.id // Compare by ID for simplicity
        }
    }

    // MARK: - Body
    var body: some View {
        // Use NavigationView to enable NavigationLink, but hide its bar elements
        NavigationView {
            ZStack(alignment: .top) {
                // --- Map View ---
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
                    self.locations = loadLocations() // Load saved favorites
                    resetMap()
                    searchCompleter.setRegion(mapRegion)
                }
                .onChange(of: locations) { _ in saveLocations() } // Save on change
                .onChange(of: locationManager.currentLocation) { handleLocationChange($0) }
                .onTapGesture { isSearchFocused = false } // Dismiss keyboard on map tap

                VStack(spacing: 0) {
                                    // --- Search Bar H-Stack ---
                                    HStack(spacing: 0) { // Use spacing 0 for overlay approach
                                        // Overlay the TextField with the clear button
                                        ZStack(alignment: .trailing) {
                                             TextField("Buscar destino...", text: $searchCompleter.searchQuery)
                                                 .focused($isSearchFocused)
                                                 // Add padding to the right to make space for the button
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

                                            // Clear button (X Mark)
                                            if !searchCompleter.searchQuery.isEmpty {
                                                Button {
                                                    searchCompleter.searchQuery = "" // Clear the text
                                                    searchCompleter.completions = [] // Clear suggestions
                                                    selectedLocation = nil // Clear selection if any
                                                    route = nil // Clear route
                                                } label: {
                                                    Image(systemName: "xmark.circle.fill")
                                                        .foregroundColor(.gray)
                                                }
                                                .padding(.trailing, 8) // Position inside the text field padding
                                            }
                                        } // End ZStack for TextField Overlay

                                        // Favorites button
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
                                        .padding(.leading, 10) // Increased space from text field
                                    } // End Search Bar H-Stack
                                    .padding(.horizontal)
                                    .padding(.top, 15)

                                    // --- Suggestions List ---
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
                    

                    // --- Favorites List ---
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

                    Spacer() // Pushes bottom button down

                    // --- Bottom "Start Traveling" Button ---
                    HStack { // Wrap button in HStack to constrain width if needed
                         Spacer() // Centers the button if width isn't full
                         NavigationLink(destination: CameraView(), isActive: $navigateToCamera) {
                              Button(action: {
                                   navigateToCamera = true
                                   isSearchFocused = false
                              }) {
                                   Text("Empezar a viajar")
                                        .font(.headline.weight(.semibold))
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity) // Button takes full width within constraints
                                        .padding(.vertical, 12)
                                        .background(selectedLocation != nil ? Color.blue : Color.gray)
                                        .cornerRadius(10)
                                        .shadow(radius: 3)
                              }
                              .disabled(selectedLocation == nil)
                         }
                         .frame(maxWidth: 400) // Max width for the button link
                         Spacer() // Centers the button
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 15) // Space from bottom edge

                } // End Main UI VStack

                // --- Recenter Button ---
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
                        // Adjust padding to clear the bottom button
                        .padding(.bottom, 80) // Increased padding
                        .padding(.trailing, 20) // Adjust horizontal padding
                    }
                } // End Recenter Button VStack

            } // End ZStack
             // --- Modifiers applied to ZStack ---
            .navigationBarHidden(true) // Hide the default navigation bar
            .navigationBarBackButtonHidden(true) // Explicitly hide the back button
            .alert("Agregar a favoritos", isPresented: $showingAddToFavorites, presenting: selectedLocation) { locationToAdd in
                Button("Agregar") { addFavorite(locationToAdd) }
                Button("Cancelar", role: .cancel) {}
            } message: { location in
                Text("¿Deseas agregar \"\(location.name)\" a tus favoritos?")
            }

        } // End NavigationView
        .navigationViewStyle(.stack) // Use stack style
        .navigationBarBackButtonHidden(true)
    } // End body

    // MARK: - Constants and Computed Properties
    let itemHeight: CGFloat = 60

    var annotations: [MKAnnotation] {
        // Create annotations from saved locations
        var allAnnotations: [MKAnnotation] = locations.map { location in
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            annotation.title = location.name
            return annotation
        }
        // Add annotation for the currently selected destination if it's not already a favorite
        if let selected = selectedLocation, !locations.contains(where: { $0.id == selected.id }) {
            let annotation = MKPointAnnotation()
            annotation.coordinate = selected.coordinate
            annotation.title = selected.name
            allAnnotations.append(annotation)
        }
        return allAnnotations
    }

    // MARK: - Methods

    /// Handles taps on map annotations.
    func handleAnnotationTap(_ annotation: MKAnnotation) {
        guard !(annotation is MKUserLocation) else { return }

        let tappedCoordinate = annotation.coordinate
        let tappedTitle = annotation.title ?? "Ubicación seleccionada"

        // Find if the tapped annotation corresponds to an existing favorite
        if let existingFavorite = locations.first(where: { $0.latitude == tappedCoordinate.latitude && $0.longitude == tappedCoordinate.longitude }) {
            selectLocation(existingFavorite) // Select the favorite directly
        } else {
            // If not a favorite, create a temporary location
            let tappedLocation = Location(name: tappedTitle ?? "Punto de interés", coordinate: tappedCoordinate)
            self.selectedLocation = tappedLocation // Show it as selected
            self.showingAddToFavorites = true // Ask user if they want to save it
        }
        isSearchFocused = false
    }

    /// Handles taps on search suggestions.
    func handleCompletionTap(_ completion: MKLocalSearchCompletion) {
        searchCompleter.searchQuery = completion.title
        isSearchFocused = false
        searchCompleter.completions = []
        search(for: completion) // Perform detailed search for the selected completion
    }

    /// Performs a detailed search based on an MKLocalSearchCompletion.
    func search(for suggestedCompletion: MKLocalSearchCompletion) {
        print("Searching details for suggestion: \(suggestedCompletion.title)")
        let searchRequest = MKLocalSearch.Request(completion: suggestedCompletion)
        let search = MKLocalSearch(request: searchRequest)
        search.start { response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error detailed search: \(error.localizedDescription)")
                    return
                }
                guard let mapItem = response?.mapItems.first else {
                    print("Detailed search yielded no results.")
                    return
                }
                let coordinate = mapItem.placemark.coordinate
                let locationName = mapItem.name ?? suggestedCompletion.title
                let newLocation = Location(name: locationName, coordinate: coordinate)
                self.selectLocation(newLocation) // Select the found location
            }
        }
    }

    /// Performs a search based on the raw query string (fallback).
    func searchLocation(query: String) {
        guard !query.isEmpty else { return }
        print("Performing fallback search for query: \(query)")
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
                guard let mapItem = response?.mapItems.first else {
                    print("Fallback search yielded no results for query: \(query)")
                    return
                }
                let coordinate = mapItem.placemark.coordinate
                let location = Location(name: mapItem.name ?? query, coordinate: coordinate)
                self.selectLocation(location) // Select the first result
            }
        }
    }

    /// Sets the selected location, updates map, and calculates route.
    func selectLocation(_ location: Location) {
        print("Selecting location: \(location.name)")
        self.selectedLocation = location
        self.isFollowingUserLocation = false
        self.mapRegion = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        calculateRoute(to: location.coordinate)
    }

    /// Calculates route using MKDirections.
    func calculateRoute(to destination: CLLocationCoordinate2D) {
        guard let userCoordinate = locationManager.currentLocation?.coordinate else {
            print("User location unavailable for route calculation.")
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
                self.route = response?.routes.first // Assign the calculated route
                if let route = self.route {
                    // Adjust map region to show the route with padding
                    self.mapRegion = MKCoordinateRegion(route.polyline.boundingMapRect.insetBy(dx: -3000, dy: -3000))
                    self.isFollowingUserLocation = false
                } else {
                    print("No routes found.")
                }
            }
        }
    }

    /// Handles changes in the user's location.
    func handleLocationChange(_ newLocation: EquatableLocation?) {
        if let coordinate = newLocation?.coordinate, isFollowingUserLocation {
            mapRegion.center = coordinate
        }
        // Update completer region based on current map view
        searchCompleter.setRegion(mapRegion)
    }

    /// Recenter map on the user's current location.
    func recenterMapOnUserLocation() {
        if let userCoordinate = locationManager.currentLocation?.coordinate {
            mapRegion = MKCoordinateRegion(
                center: userCoordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
            isFollowingUserLocation = true
        }
    }

    /// Adds a location to the favorites list (triggers save via onChange).
    func addFavorite(_ locationToAdd: Location) {
         // Avoid adding exact duplicates (check coordinates)
         if !locations.contains(where: { $0.latitude == locationToAdd.latitude && $0.longitude == locationToAdd.longitude }) {
             locations.append(locationToAdd)
             print("Added \(locationToAdd.name) to favorites.")
         } else {
             print("\(locationToAdd.name) is already a favorite.")
         }
    }

    /// Removes a location from the favorites list (triggers save via onChange).
    func removeLocation(_ location: Location) {
        locations.removeAll { $0.id == location.id }
        print("Removed \(location.name).")
        if selectedLocation?.id == location.id {
            selectedLocation = nil
            route = nil
        }
    }

    /// Resets map state and clears search/selection.
    func resetMap() {
        selectedLocation = nil
        route = nil
        isFollowingUserLocation = true // Resume following user
        if locationManager.currentLocation != nil {
             recenterMapOnUserLocation() // Center only if location is available
        }
        searchCompleter.searchQuery = ""
        searchCompleter.completions = []
        isSearchFocused = false
        showFavorites = false // Hide favorites list on reset
    }

    // MARK: - Persistence Functions
    private func getLocationsFileURL() -> URL {
        // Use default FileManager to get Documents directory
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
             // Fallback or handle error appropriately if Documents directory is unavailable
             fatalError("Unable to access Documents directory.")
        }
        return documentsDirectory.appendingPathComponent("favoriteLocations.json")
    }

    private func loadLocations() -> [Location] {
        let fileURL = getLocationsFileURL()
        print("Loading locations from: \(fileURL.path)")
        // Check if the file exists before attempting to load
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
             print("Locations file not found, starting with empty list.")
             return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let loadedLocations = try decoder.decode([Location].self, from: data)
            print("Loaded \(loadedLocations.count) locations successfully.")
            return loadedLocations
        } catch {
            print("Failed to load locations: \(error)")
            return [] // Return empty array on error
        }
    }

    private func saveLocations() {
        let fileURL = getLocationsFileURL()
        print("Saving \(locations.count) locations to: \(fileURL.path)")
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // For easier debugging
            let data = try encoder.encode(locations)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection]) // Atomic write + encryption
            print("Locations saved successfully.")
        } catch {
            print("Failed to save locations: \(error)")
            // Consider showing an error to the user
        }
    }

}

// MARK: - Extensions (Required Dependencies)
extension MKLocalSearchCompletion: Identifiable {
    public var id: String { title + subtitle }
}

