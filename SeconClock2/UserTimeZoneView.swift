//
//  UserTimeZoneView.swift
//  SeconClock2
//
//  Created by Holger Krupp on 17.08.23.
//

import SwiftUI
import CoreLocation



struct UserTimeZoneView: View {
    @EnvironmentObject var timetravel: Timetravel
    @State var tz: UserTimeZone
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    @State var timetext = ""
    @State private var maxWidth: CGFloat = .zero
    var body: some View {
      
        VStack{
         //   Text("TimeTravel:\(timetravel.offset.description)")
            HStack{
                TextField("Set custom name" , text: $tz.name.toUnwrapped(defaultValue: ""))
                    .textFieldStyle(.roundedBorder)
                    .help("Set custom name" )
                
                Toggle(isOn: $tz.selected.toUnwrapped(defaultValue: false), label: {
                    if tz.selected == true{
                        Image(systemName: "menubar.arrow.down.rectangle")
                            .background(rectReader($maxWidth))
                            .frame(minWidth: maxWidth)
                    }else{
                        Image(systemName: "menubar.arrow.up.rectangle")
                            .background(rectReader($maxWidth))
                            .frame(minWidth: maxWidth)
                    }
                })
                .toggleStyle(.button)
                .help("Add to menu bar")
                
                .id(maxWidth)
            }
            HStack(alignment: .top){
                
                        Text(timetext)
                            .onReceive(timer) { _ in
                                self.timetext = time2text()
                            }
                            .help("Local time")
                        Spacer()
                        Text(tz.timezone?.identifier ?? tz.name ?? "")
                            .font(.caption)
                            .help("Timezone identifier")
                   
              
                    
                    
                    Button(role: .destructive) {
                        withAnimation{
                            tz.delete()
                        }
                        
                        
                    } label: {
                        Image(systemName: "trash")
                            .background(rectReader($maxWidth))
                            .frame(minWidth: maxWidth)
                        // Image(systemName: "star.fill")
                    }
                    .help("Remove from favorites")
                    
                    .id(maxWidth)
                    
                
            }
          /*
            if let sunset = tz.sunset, let sunrise = tz.sunrise{
                DayTimeSliderView(sunrise: sunrise, sunset: sunset,now: tz.date)
                    
                    .padding([.bottom])
          
            }
            */
        }
        
    }
    
    init(tz: UserTimeZone, timetext: String = "") {
        self.tz = tz
        self.timetext = timetext
        self.timetext = time2text()
    }
    
    func time2text() -> String{
        return tz.currentTime
    }
    
    // helper reader of view intrinsic width
    private func rectReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { gp -> Color in
            DispatchQueue.main.async {
                binding.wrappedValue = max(binding.wrappedValue, gp.frame(in: .local).width)
            }
            return Color.clear
        }
    }
    
    
}

#Preview {
    UserTimeZoneView(tz: UserTimeZone(with: "Africa/Kigali"))
        .padding()
}



extension Binding {
    func toUnwrapped<T>(defaultValue: T) -> Binding<T> where Value == Optional<T>  {
        Binding<T>(get: { self.wrappedValue ?? defaultValue }, set: { self.wrappedValue = $0 })
    }
}
