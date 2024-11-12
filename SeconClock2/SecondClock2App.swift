//
//  SeconClock2App.swift
//  SeconClock2
//
//  Created by Holger Krupp on 16.08.23.
//

import SwiftUI
import SwiftData

@main
struct SecondClock2App: App {
   
    let modelContainer: ModelContainer
    //var migration = Migration()


    
    
    init() {
        do {
            modelContainer = try ModelContainer(for: UserTimeZone.self)
        } catch {
            fatalError("Could not initialize ModelContainer")
        }
        
        
        
    }


    var body: some Scene {
        
        
        
        
        MenuBarExtra {
            
            SearchView()
                .modelContainer(modelContainer)
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, maxHeight: .infinity)
            
            Divider()
            HStack{
                LaunchAtLoginView()
                Spacer()
                Button {
                    NSApplication.shared.terminate(nil)
                } label: {
                    Text("Quit")
                }
            }
            
           
            .padding()
           

            
        } label: {
            
            MenuTextView()
                .modelContainer(modelContainer)
            
        }
        .menuBarExtraStyle(.window)
        
        

        }
}

