//
//  SearchView.swift
//  SeconClock2
//
//  Created by Holger Krupp on 16.08.23.
//

import SwiftUI
import MapKit
import SwiftData

struct SearchView: View {
    @Environment(\.modelContext) private var modelContext

    @ObservedObject var locVM: LocationManager = LocationManager.shared

    let specialTimeZones = ["","UTC",".beat", "UNIX Timestamp", "New Earth Time", "Eternal September"]
    
     var special = [
        [
            "name": "",
            "identifier":"",
            "added":false,
            "enable": false
        ],
        [
            "name": "Swatch Beats",
            "identifier": ".beat",
            "added":false,
            "enable": true
        ],
        [
            "name": "UNIX Timestamp",
            "identifier":"UNIX Timestamp",
            "added":false,
            "enable": true
        ],
        [
            "name": "New Earth Time",
            "identifier":"New Earth Time",
            "added":false,
            "enable": true
        ],
        [
            "name": "Eternal September",
            "identifier":"Eternal September",
            "added":false,
            "enable": true
        ]
    
    
    ]
    
    
    @State var selectedSpecialZone:String = ""
    
    
    var body: some View {
      
            VStack{
                
                ZStack(alignment: .trailing) {
                    TextField("Search..", text: $locVM.searchText)
                        .textFieldStyle(.roundedBorder)
                    if locVM.searchText.count > 0{
                        Image(systemName: "xmark.circle.fill")
                            .padding([.trailing], 5)
                            .foregroundColor(.secondary)
                            .onTapGesture {
                                locVM.searchText = ""
                            }
                    }
                }
                
                Spacer()
                HStack{
                    Picker("Special", selection: $selectedSpecialZone ) {
                        ForEach(specialTimeZones, id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Button(action: {
                        withAnimation {
                            // locVM.searchText = ""
                            let newTZ = UserTimeZone(with: selectedSpecialZone)
                            newTZ.name = selectedSpecialZone
                            modelContext.insert(newTZ)
                        }
                        
                    }, label: {
                        
                        Text("Add")
                    })
                    .disabled(selectedSpecialZone == "")
                    
                    
                }
                
                
                Divider()
                
                ZStack{
                 
                        UserTimeZoneListView()
                            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity)
                    
                    
                    
                    if !locVM.searchResults.isEmpty, locVM.searchText != ""{
                        List(locVM.searchResults, id: \.self){
                            SearchViewRow(searchResult: $0)
                            
                            
                        }
                        .background(.thinMaterial)
                        
                        
                    }
                        
                    
                    
                }
            }.padding()
                
        
        
    }
}

struct SearchViewRow:View{
    @Environment(\.modelContext) private var modelContext
    var searchResult: MKLocalSearchCompletion
    @State var timeZone: TimeZone?
    @State private var isHidden = false
    
    @ObservedObject var locVM: LocationManager = LocationManager.shared
    @State var added:Bool = false

    
    var body: some View {
        VStack{
            HStack{
                
                VStack(alignment: .leading){
                    Text(searchResult.title)
                        .font(.title3)
                    Text(searchResult.subtitle)
                        .font(.subheadline)
                    
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        Task{
                            let tz = await locVM.getLocation(searchResult: searchResult)?.first?.timeZone
                            timeZone = tz
                        }
                        isHidden.toggle()
                    }
                }, label: {
                    Image(systemName: "clock.badge.questionmark")
                })
                .help("Show details")
                Button(action: {
                    Task{
                        if let location = await locVM.getLocation(searchResult: searchResult)?.first
                        {
                            if let tz = location.timeZone {
                                withAnimation {
                                    // locVM.searchText = ""
                                    let newTZ = UserTimeZone(with: tz)
                                    newTZ.name = searchResult.title
                                   
                                    newTZ.lat = location.placemark.coordinate.latitude
                                    newTZ.lon = location.placemark.coordinate.latitude
                                    
                                    modelContext.insert(newTZ)
                                    added = true
                                }
                            }
                        }
                        
                    }
                }, label: {
                    if added{
                        Image(systemName: "star.fill")
                    }else{
                        Image(systemName: "star")
                    }
                })
                .help("Add to favorites")
                
            }
            Group{
                HStack{
                    
                    
                    Text(timeZone?.identifier ?? "")
                    Spacer()
                    if let tz = timeZone{
                        Text(Date().convertToTimeZone(initTimeZone: TimeZone.current, timeZone: tz ).formatted())

                    }
                }
            }
            .frame(height: isHidden ? nil : 0, alignment: .top)
            .clipped()
            .frame(maxWidth: .infinity)
            .background(.windowBackground)
            .padding()
        }
       
    
        
        
    }
}

#Preview {
    SearchView()
}
