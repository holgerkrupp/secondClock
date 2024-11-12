//
//  MenuTextView.swift
//  SeconClock2
//
//  Created by Holger Krupp on 18.08.23.
//

import SwiftUI
import SwiftData
struct MenuTextView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query(filter: #Predicate<UserTimeZone> { $0.selected == true },
           sort: [SortDescriptor(\.order)] )
    var selectedTimeZones: [UserTimeZone]

    
    @State var text: String = ""
    
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
 

    var body: some View {
        Text(text)
            .onReceive(timer) { _ in
                self.text = menutext()
                
                // migrating from SecondClock1 to 2. by reading the old TimeZone and creating a new one.
                
                if getObjectForKeyFromPersistentStorrage("TimeZone") is String{
                    let tz = UserTimeZone(migration: true)
                    modelContext.insert(tz)

                    do{
                        try modelContext.save()
                    }catch{
                        print("could not save recovered TZ")
                    }
                }
                // the migration should be removed in September 2024
                
            }
            .font(.system(size: 14).monospacedDigit())
         
        
    }
    init(){
       // let migration = Migration() // migrating from SecondClock1 to 2. by reading the old TimeZone and creating a new one.
        

        
        self.text = menutext()
        
    }
    
    func menutext() -> String{
        

        
        
        var text:String = ""
        
        for tz in (selectedTimeZones){
            
            //     text.appending("asd")
            
            text.append("\(tz.readName()) \(tz.currentTime)")
            if selectedTimeZones.last != tz {
                text.append(" \u{2022} ")
            }
        }
        if text == "" {
            return "SecondClock"
        }else{
            return text
        }
        
    }
    
    
}

#Preview {
    MenuTextView()
}
