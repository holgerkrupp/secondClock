//
//  LocationManager.swift
//  SeconClock2
//
//  Created by Holger Krupp on 16.08.23.
//

import Foundation
import MapKit
import Combine

class LocationManager: NSObject, ObservableObject{

    
    
 
    static let shared = LocationManager()
    
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
    
    
}

extension LocationManager: MKLocalSearchCompleterDelegate{
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
    }
    
    
    
    func getLocation(searchResult: MKLocalSearchCompletion) async -> [MKMapItem]? {
        await withCheckedContinuation { continuation in
            
            let searchRequest = MKLocalSearch.Request(completion: searchResult)
            let search = MKLocalSearch(request: searchRequest)
            search.start { (response, error) in
                continuation.resume(returning: response?.mapItems)
            }
            
        }
    }

    
    
}




