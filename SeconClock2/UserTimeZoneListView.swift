//
//  UserTimeZoneListView.swift
//  SeconClock2
//
//  Created by Holger Krupp on 17.08.23.
//

import SwiftUI
import SwiftData

class Timetravel: ObservableObject{
    @Published var offset:TimeInterval = 0.0
    
}


struct UserTimeZoneListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query private var timeZones: [UserTimeZone]
    var body: some View {
        
        @State var timetravel = Timetravel()
     //   List(timeZones, id: \.self){
        
      //  Text("TimeTravel: \(timetravel.offset.description)")
        List{
            ForEach(timeZones.sorted(by: {$0.order ?? 0 < $1.order ?? 0})) { zone in
                
                //   UserTimeZoneView(tz: $0)
                UserTimeZoneView(tz: zone)
                
                if let sunset = zone.sunset, let sunrise = zone.sunrise{
                    DayTimeSliderView(sunrise: sunrise, sunset: sunset,now: zone.date)
                    
                        .padding([.bottom])
                    
                }
                
            }
            .onMove( perform: move )
        }
        .environmentObject(timetravel)
            if timeZones.count == 0{
                Text("no TimeZones saved")
            }
        
    }
    
    
    private func move( from source: IndexSet, to destination: Int)
    {
        // Make an array of items from fetched results
        var revisedItems: [ UserTimeZone  ] = timeZones.map{ $0 }
        
        // change the order of the items in the array
        revisedItems.move(fromOffsets: source, toOffset: destination )
        
        // update the userOrder attribute in revisedItems to
        // persist the new order. This is done in reverse order
        // to minimize changes to the indices.
        for reverseIndex in stride( from: revisedItems.count - 1,
                                    through: 0,
                                    by: -1 )
        {
            revisedItems[ reverseIndex ].order =
            Int( reverseIndex )
        }
    }
    
}

#Preview {
    UserTimeZoneListView()
}


