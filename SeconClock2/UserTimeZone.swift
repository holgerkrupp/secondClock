//
//  UserTimeZone.swift
//  SeconClock2
//
//  Created by Holger Krupp on 16.08.23.
//

import Foundation
import SwiftData
import CoreLocation


@Model
class UserTimeZone {
    var name: String?
    var identifier: String?
    var selected: Bool?
    var order: Int?
    var lat: Double?
    var lon: Double?
    
    var timezone: TimeZone?{
        get{
            if let identifier{
                return TimeZone(identifier: identifier)
            }else{
                return nil
            }
               
            
        }
        set{
            identifier = newValue?.identifier ?? ""
        }
    }
    
    init(with: TimeZone){
        timezone = with
        identifier = timezone?.identifier
        name = readName()
        order = 0
        selected = false
    }
    
    init(with: String){

        if let tz = TimeZone.init(identifier: with)
        {
            timezone = tz
        }else if with == "UTC"{
            timezone = TimeZone.init(identifier: "Etc/UTC")
        }
        identifier = with
        name = readName()
        order = 0
        selected = false

    }
    
    init(migration: Bool){
        if migration{
            if let savedZone = getObjectForKeyFromPersistentStorrage("TimeZone") as? String{
                if let savedtime  = TimeZone.init(identifier: savedZone)
                {
                    timezone = savedtime
                    identifier = savedtime.identifier
                    name = getObjectForKeyFromPersistentStorrage("TimeZoneName") as? String
                    selected = true
                    order = 0

                }
                removeObjectForKeyToPersistentStorrage("TimeZone")
            }
        }
    }
    
    

    
    
    
    func delete(){
        if let modelContext {
            modelContext.delete(self)
        }
    }
    
    
    func readName() -> String{
        
        var returnvalue = ""
        
        if let tz = timezone{
            returnvalue = tz.identifier.components(separatedBy: "/").last ?? ""
        }
        
        if let name, name != "" {
            
            returnvalue = name
            
        }else{
            returnvalue = identifier ?? ""
            
        }
        return returnvalue
    }
    
    
    var date: Date?{
        if let tz = timezone{

            return Date().convertToTimeZone(initTimeZone: TimeZone.current, timeZone: tz )
        }else{
            return nil
        }
        
    }
    
    var sunrise:Date?{
        if let lat, let lon {
            return date?.sunrise(CLLocation(latitude: lat, longitude: lon))
        }else{
            return nil
        }
    }
    
    var sunset:Date?{
        if let lat, let lon {
            return date?.sunset(CLLocation(latitude: lat, longitude: lon))
        }else{
            return nil
        }
    }
    
    
    var currentTime: String{
        if identifier == ".beat"{
          /*  let beats = Date().beats
            let datestring = String(format: "@%03.0f", beats)
            return datestring
           */
            return Date().beatString
        }else if identifier == "UNIX Timestamp"{
            let timestamp = Date().timeIntervalSince1970
            let datestring = String(format: "%.0f", timestamp)
            return datestring
        }else if identifier == "New Earth Time"{
            let earthTime = Date().NewEartTime
            return earthTime
        }else if identifier == "Eternal September"{
            if let dateString = Date().eternalSeptember{
                return dateString
            }else{
                return "error"
            }
        }else if let tz = timezone{
            let dateformatter = DateFormatter()
            dateformatter.timeZone = tz
            
            dateformatter.timeStyle = .short
            let now = Date()
            
         //   let weekday = dateformatter.weekdaySymbols[Calendar.current.component(.weekday, from: now)-1]
         //   let datestring = ("\(weekday) \(dateformatter.string(from: now))")
              let datestring = dateformatter.string(from: now)

            
            return datestring
        }else{
            
            return "--"
        }
    }
    
    
}

func getObjectForKeyFromPersistentStorrage(_ key:String) -> Any?{
    
    if let object = UserDefaults.standard.object(forKey: key){
        return object as AnyObject?
    }else{
        return nil
    }
}
func removeObjectForKeyToPersistentStorrage(_ key:String){
    UserDefaults.standard.removeObject(forKey: key)
}

extension Date {
    
  
    
    var NewEartTime: String{
        
        
        // *** Create date ***
        let date = Date()
        
        // *** create calendar object ***
        var calendar = Calendar.current
        // *** define calendar components to use as well Timezone to UTC ***
        calendar.timeZone = TimeZone(identifier: "UTC")!
        
        
        // *** Get Individual components from date ***
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        // let seconds = calendar.component(.second, from: date)
        
        let netDegrees = (hour * 60 / 4) + (minutes / 4)
        let netMinutes = ((minutes % 4) * 60 / 4)
        
        let NewEarthTime = "\(netDegrees)° \(netMinutes)' NET"
        
        return NewEarthTime
    }
    
    
    var eternalSeptember: String?{
        let dateFormatter = DateFormatter()
        
        
        dateFormatter.dateFormat = "yyyy'-'MM'-'dd"
        if let from = dateFormatter.date(from: "1993-09-01"){
            let seconds = timeIntervalSince(from)
            let days = seconds / 60 / 60 / 24 // +1 hatte ich, ist aber glaube ich falsch
            
            var string = String(format: "%.0f. Sep 1993", days)
            
            if dateFormatter.locale.identifier == "en_US"{
                string = String(format: "Sep %.0f. 1993", days)
            }
            
            return string
        }
        return nil
    }
    
    var beats: Float {
        var components = Calendar.current
            .dateComponents([.timeZone, .year, .month, .day, .hour, .minute, .second], from: self)
        components.timeZone = TimeZone(identifier: "UTC+1") // Yes, UTC+1 is correct as reference for .beats
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        guard let midnight = Calendar.current.date(from: components) else { return 0 }
        
        let seconds = self.timeIntervalSince(midnight)
        
        var currentBeats = fmod(Float((seconds / 86400.0) * 1000.0), 1000.0)
        if currentBeats < 0 {
            currentBeats += 1000.0
        }
        return currentBeats
    }
    
    var nearestBeat: Int {
        return Int(floor(self.beats))
    }
    
    var beatString: String{
        return String(nearestBeat)
    }
    
    func convertToTimeZone(initTimeZone: TimeZone, timeZone: TimeZone) -> Date {
        let delta = TimeInterval(timeZone.secondsFromGMT(for: self) - initTimeZone.secondsFromGMT(for: self))
        return addingTimeInterval(delta)
    }
}
