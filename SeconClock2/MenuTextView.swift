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
                                
            }
            .font(.system(size: 14).monospacedDigit())
         
        
    }
    init(){

        

        
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
