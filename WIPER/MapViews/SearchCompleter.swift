//
//  SearchCompleter.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 27/04/25.
//

import MapKit
import Combine // Needed for ObservableObject

// Helper class to manage MKLocalSearchCompleter
class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = ""
    @Published var completions = [MKLocalSearchCompletion]() // Results to display
    private var searchCompleter = MKLocalSearchCompleter()
    private var cancellable: AnyCancellable?

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]

        // Use Combine to debounce search query updates
        cancellable = $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main) // Add a small delay
            .removeDuplicates() // Don't search if the query hasn't changed
            .sink { [weak self] query in
                if !query.isEmpty {
                    self?.searchCompleter.queryFragment = query
                    print("Updating query fragment: \(query)") // Debug print
                } else {
                    // Clear results when query is empty
                    self?.completions = []
                    print("Query empty, clearing completions.") // Debug print
                }
            }
    }

    // Delegate method when completions are updated
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        // Update the published completions array on the main thread
        DispatchQueue.main.async {
            self.completions = completer.results
             print("Received \(completer.results.count) completions.") // Debug print
        }
    }

    // Delegate method for handling errors
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("Search completer failed with error: \(error.localizedDescription)")
            self.completions = [] // Clear completions on error
        }
    }

    // Optional: Set region for localized results
    func setRegion(_ region: MKCoordinateRegion) {
        searchCompleter.region = region
    }
}
