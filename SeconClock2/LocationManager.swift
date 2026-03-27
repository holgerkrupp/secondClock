//
//  LocationManager.swift
//  SeconClock2
//
//  Created by Holger Krupp on 16.08.23.
//

import Foundation
import MapKit
import Combine

struct SearchLocation: Sendable {
    let timeZoneIdentifier: String?
    let latitude: Double
    let longitude: Double

    var timeZone: TimeZone? {
        guard let timeZoneIdentifier else {
            return nil
        }

        return TimeZone(identifier: timeZoneIdentifier)
    }
}

class LocationManager: NSObject, ObservableObject{
    @MainActor static let shared = LocationManager()
    
    @Published var searchText: String = ""
    var publisher: AnyCancellable?
    
    
    var searchCompleter = MKLocalSearchCompleter()
    @Published var searchResults = [MKLocalSearchCompletion]()
    @Published var locations = [MKMapItem]()

    private override init() {
        super.init()
        searchCompleter.resultTypes = [.address, .pointOfInterest]
        //self.searchCompleter.pointOfInterestFilter = .excludingAll
        
        self.publisher = $searchText.receive(on: RunLoop.main).sink {
           
            self.searchCompleter.queryFragment = $0
        }
        searchCompleter.delegate = self
    }
    
    func searchfor(location: String){
        
    }
    
    
    
    @MainActor
    static func getLocation(searchResult: MKLocalSearchCompletion) async -> SearchLocation? {
        await withCheckedContinuation { continuation in
            let searchRequest = MKLocalSearch.Request(completion: searchResult)
            let search = MKLocalSearch(request: searchRequest)
            search.start { (response, error) in
                let location = response?.mapItems.first.map { item in
                    let coordinate = item.placemark.coordinate
                    return SearchLocation(
                        timeZoneIdentifier: item.timeZone?.identifier,
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude
                    )
                }

                continuation.resume(returning: location)
            }
        }
    }

    @MainActor
    static func getLocation(query: String) async -> SearchLocation? {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return nil
        }

        return await withCheckedContinuation { continuation in
            let searchRequest = MKLocalSearch.Request()
            searchRequest.naturalLanguageQuery = trimmedQuery

            let search = MKLocalSearch(request: searchRequest)
            search.start { response, _ in
                let location = response?.mapItems.first(where: { $0.timeZone != nil }).map { item in
                    let coordinate = item.placemark.coordinate
                    return SearchLocation(
                        timeZoneIdentifier: item.timeZone?.identifier,
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude
                    )
                }

                continuation.resume(returning: location)
            }
        }
    }

    @MainActor
    static func getLocation(queries: [String]) async -> SearchLocation? {
        for query in queries {
            if let location = await getLocation(query: query) {
                return location
            }
        }

        return nil
    }
}

extension LocationManager: MKLocalSearchCompleterDelegate{
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
    }
}
