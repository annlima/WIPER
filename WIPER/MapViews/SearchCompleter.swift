//
//  SearchCompleter.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 27/04/25.
//

import MapKit
import Combine

class SearchCompleter: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var searchQuery = ""
    @Published var completions = [MKLocalSearchCompletion]()
    private var searchCompleter = MKLocalSearchCompleter()
    private var cancellable: AnyCancellable?

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]

        cancellable = $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if !query.isEmpty {
                    self?.searchCompleter.queryFragment = query
                    print("Updating query fragment: \(query)")
                } else {
                    self?.completions = []
                    print("Query empty, clearing completions.")
                }
            }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.completions = completer.results
             print("Received \(completer.results.count) completions.")
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("Search completer failed with error: \(error.localizedDescription)")
            self.completions = [] 
        }
    }

    func setRegion(_ region: MKCoordinateRegion) {
        searchCompleter.region = region
    }
}
