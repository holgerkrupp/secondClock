//
//  DayTimeSliderView.swift
//  SecondClock2
//
//  Created by Holger Krupp on 22.08.23.
//

import SwiftUI

struct DayTimeSliderView: View {
    
    @State var date = Date()
    var now:Date?
    var sunset:Date?
    var sunrise:Date?
    
    @State var nightColor:Color = .black
    @State var dayColor:Color = .blue
    
    @State var barheight:CGFloat = 10 // Slider Bar Height
    @State var buttonDiameter:CGFloat = 20 // Slider Button Diameter
    
    var posSunrise:CGFloat = 0.0
    var posSunset:CGFloat = 1.0
    var widthFactor:CGFloat { return posSunset - posSunrise }
    
    
    var nowPosition:CGFloat = 0.0
    
    let nightImage = Image("stars")
    let dayImage = Image("clouds")
    var starsY = 0
    
    //var widthFactor:CGFloat { return pos2 - pos1 }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                
                Rectangle()
                    .foregroundColor(.clear)
                    .frame(width: nil, height: self.barheight, alignment: .center)
                    .background(
                        nightImage
                
                            .scaledToFill()
                        
                            .frame(width: geometry.size.width, height: self.barheight, alignment: .leading)
                            .clipped()
                        )

                
                // Active Overlay here
                Rectangle()
                
                    .foregroundColor(.clear)
                    .frame(width: nil, height: self.barheight, alignment: .center)
                    .background(
                        dayImage
      
                            .scaledToFill()
                        
                            .frame(width: geometry.size.width * self.widthFactor, height: self.barheight, alignment: .center)
                            .clipped()
                    )
                    .frame(width: geometry.size.width * self.widthFactor, height: self.barheight, alignment: .center)
                    .position(x: geometry.size.width * (self.posSunrise + (self.widthFactor/2.0)), y: geometry.size.height/2.0)
                
                

                
                // Sunrise/Set marker
                if sunrise != nil{
                    Image(systemName:"sunrise")
                        .foregroundColor(.yellow)
                    
                        .frame(width: self.buttonDiameter, height: self.buttonDiameter, alignment: .center)
                        .position(x: geometry.size.width * self.posSunrise, y: geometry.size.height/2.0)
                    
                    Text(sunrise?.formatted(date: .omitted, time: .shortened) ?? "")
                        .foregroundColor(.primary)
                        .frame(width: nil, height: self.barheight, alignment: .center)
                        .position(x: geometry.size.width * self.posSunrise, y: geometry.size.height/2.0+self.barheight*1.5)
                    
                }
                if sunset != nil{
                    Image(systemName:"sunset")
                        .foregroundColor(.orange)
                        .foregroundColor(self.nightColor)
                        .frame(width: self.buttonDiameter, height: self.buttonDiameter, alignment: .center)
                        .position(x: geometry.size.width * self.posSunset, y: geometry.size.height/2.0)
                    
                    Text(sunset?.formatted(date: .omitted, time: .shortened) ?? "")
                        .foregroundColor(.primary)
                        .frame(width: nil, height: self.barheight, alignment: .center)
                        .position(x: geometry.size.width * self.posSunset, y: geometry.size.height/2.0+self.barheight*1.5)
                        //.padding([.top])
                }
                
                //Now Marker
                if now != nil{
                    Rectangle()
                        .foregroundColor(.accentColor)
                        .frame(width: 2, height: self.barheight, alignment: .center)
                        .position(x: geometry.size.width * (self.nowPosition), y: geometry.size.height/2.0)
                    /*    .gesture(DragGesture()
                            .onChanged({ value in
                                // Caluclate the scaled position
                                let newPos = value.location.x / geometry.size.width
                                //    self.nowPosition = newPos
                                // self.nowPosition = newPos
                            }))
                     */
                }
            }
            
        }
    }
    init(sunrise: Date? = nil, sunset: Date? = nil, now: Date? = nil){
        self.sunrise = sunrise
        self.sunset = sunset
        self.now = now
        if sunrise != nil, sunset != nil {
            setSunriseAndSunset()
        }
        setNow()
       // starsY = Int.random(in: 0..<500)
        print("StarsY: \(starsY.description)")
    }
    
    mutating func setNow(){
        if let now {
            
            nowPosition = CGFloat(now.percetageOfDay)
            print("set now Position to \(nowPosition)")
        }
        
    }
    
    
    mutating func setSunriseAndSunset(){
        posSunrise = CGFloat(sunrise?.percetageOfDay ?? 0.0)
        posSunset = CGFloat(sunset?.percetageOfDay ?? 1.0)
        print("Sunrise: \(sunrise?.formatted() ?? "-"), %: \(sunrise?.percetageOfDay.formatted() ?? "-")")
        print("pos1: \(posSunrise), pos2: \(posSunset)")
    }
    
}

#Preview {
   
    DayTimeSliderView(sunrise: Calendar.current.date(byAdding: .hour, value: -2, to: Date()), sunset: Calendar.current.date(byAdding: .hour, value: 6, to: Date()), now: Date())
  //  DayTimeSliderView()
}


extension Date {
    
    var percetageOfDay: Float{
        
        let secondsInADay = 60 + 60 * 60 + 24 * 60 * 60
        
        let hourSeconds = Calendar.current.component(.hour, from: self) * 60 * 60
        let minuteSeconds = Calendar.current.component(.minute, from: self) * 60
        let seconds = Calendar.current.component(.second, from: self)
        
        let totalSeconds = hourSeconds + minuteSeconds + seconds
        let passedSeconds = Float(totalSeconds)/Float(secondsInADay)

        print("totalSeconds: \(totalSeconds.description)")
        print("secondsInADay: \(secondsInADay.description)")
        print("passedSeconds: \(passedSeconds.formatted())")
        
        return passedSeconds
    }
    
}
