import MapKit
import SwiftUI

class MapViewModel: ObservableObject {
    @Published var searchResults: [MKMapItem] = []
    @Published var route: MKRoute?
    @Published var lookAroundScene: MKLookAroundScene?

    func searchPlaces(searchText: String, viewingRegion: MKCoordinateRegion?) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = viewingRegion ?? .userRegion

        let results = try? await MKLocalSearch(request: request).start()
        searchResults = results?.mapItems ?? []
    }


    func fetchLookAroundPreview(mapSelection: MKMapItem?) async {
        guard let mapSelection = mapSelection else { return }
        lookAroundScene = nil
        let request = MKLookAroundSceneRequest(mapItem: mapSelection)
        lookAroundScene = try? await request.scene
    }

    func fetchRoute(mapSelection: MKMapItem?) async {
        let request = MKDirections.Request()
        request.source = .init(placemark: .init(coordinate: .userLocation))
        request.destination = mapSelection
        
        let result = try? await MKDirections(request: request).calculate()
        route = result?.routes.first
    }

    func clearSearchResults() {
        searchResults.removeAll(keepingCapacity: false)
    }
}
