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
        }else if identifier == "Japanese Imperial Year"{
            return Date().japaneseImperialYear
        }else if identifier == "French Revolutionary Date"{
            return Date().frenchRevolutionaryMonthAndDay
        }else if identifier == "Discordian Date"{
            return Date().discordianDate
        }else if identifier == "French Decimal Time"{
            return Date().frenchDecimalTime
        }else if identifier == "Holocene Date"{
            return Date().holoceneDate
        }else if identifier == "Maya Long Count"{
            return Date().mayaLongCount
        }else if identifier == "ISO Week Date"{
            return Date().isoWeekDate
        }else if identifier == "Ordinal Date"{
            return Date().ordinalDate
        }else if identifier == "Julian Date"{
            return String(format: "JD %.5f", Date().julianDate)
        }else if identifier == "Modified Julian Date"{
            return String(format: "MJD %.5f", Date().modifiedJulianDate)
        }else if identifier == "Mars Time"{
            return Date().marsTime
        }else if identifier == "Greenwich Sidereal Time"{
            return Date().greenwichSiderealTime
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

extension ModelContext {
    @discardableResult
    func normalizeUserTimeZoneOrders(using orderedZones: [UserTimeZone]? = nil) -> Bool {
        let zones = orderedZones ?? ((try? fetch(FetchDescriptor<UserTimeZone>(sortBy: [SortDescriptor(\.order)]))) ?? [])

        guard !zones.isEmpty else {
            return false
        }

        var didChange = false

        for (index, zone) in zones.enumerated() where zone.order != index {
            zone.order = index
            didChange = true
        }

        if didChange {
            try? save()
        }

        return didChange
    }

    func nextUserTimeZoneOrder() -> Int {
        let descriptor = FetchDescriptor<UserTimeZone>(sortBy: [SortDescriptor(\.order)])
        let zones = (try? fetch(descriptor)) ?? []
        return zones.compactMap(\.order).max().map { $0 + 1 } ?? zones.count
    }

    func insertUserTimeZoneAtEnd(_ timeZone: UserTimeZone) {
        normalizeUserTimeZoneOrders()
        timeZone.order = nextUserTimeZoneOrder()
        insert(timeZone)
        try? save()
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

    var japaneseImperialYear: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .japanese)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "GGGG y"
        return formatter.string(from: self)
    }

    var frenchRevolutionaryMonthAndDay: String {
        let monthNames = [
            "Vendémiaire", "Brumaire", "Frimaire", "Nivôse", "Pluviôse", "Ventôse",
            "Germinal", "Floréal", "Prairial", "Messidor", "Thermidor", "Fructidor"
        ]

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        let localDay = calendar.startOfDay(for: self)
        let gregorianYear = calendar.component(.year, from: localDay)
        var yearStart = calendar.date(from: DateComponents(year: gregorianYear, month: 9, day: 22))!

        if localDay < yearStart {
            yearStart = calendar.date(from: DateComponents(year: gregorianYear - 1, month: 9, day: 22))!
        }

        let dayOfYear = calendar.dateComponents([.day], from: yearStart, to: localDay).day ?? 0

        if dayOfYear < 360 {
            return "\(monthNames[dayOfYear / 30]) \((dayOfYear % 30) + 1)"
        }

        return "Sansculottides \(dayOfYear - 359)"
    }

    var discordianDate: String {
        let seasonNames = ["Chaos", "Discord", "Confusion", "Bureaucracy", "The Aftermath"]

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        let year = calendar.component(.year, from: self)
        let yold = year + 1166
        let month = calendar.component(.month, from: self)
        let day = calendar.component(.day, from: self)

        if month == 2 && day == 29 {
            return "St. Tib's Day, \(yold) YOLD"
        }

        var dayIndex = (calendar.ordinality(of: .day, in: .year, for: self) ?? 1) - 1
        let isLeapYear = calendar.range(of: .day, in: .year, for: self)?.count == 366

        if isLeapYear && month > 2 {
            dayIndex -= 1
        }

        let season = seasonNames[dayIndex / 73]
        let seasonDay = (dayIndex % 73) + 1
        return "\(season) \(seasonDay), \(yold) YOLD"
    }

    var frenchDecimalTime: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        let start = calendar.startOfDay(for: self)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
            return "--"
        }

        let fractionOfDay = timeIntervalSince(start) / end.timeIntervalSince(start)
        let decimalSeconds = min(99_999, max(0, Int(fractionOfDay * 100_000)))
        let hour = decimalSeconds / 10_000
        let minute = (decimalSeconds / 100) % 100
        let second = decimalSeconds % 100
        return String(format: "%d:%02d:%02d", hour, minute, second)
    }

    var holoceneDate: String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMMM"

        let year = Calendar(identifier: .gregorian).component(.year, from: self) + 10_000
        return "\(formatter.string(from: self)) \(year) HE"
    }

    var isoWeekDate: String {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear, .weekday], from: self)
        let isoWeekday = ((components.weekday ?? 2) + 5) % 7 + 1
        return String(
            format: "%04d-W%02d-%d",
            components.yearForWeekOfYear ?? 0,
            components.weekOfYear ?? 0,
            isoWeekday
        )
    }

    var ordinalDate: String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let year = calendar.component(.year, from: self)
        let day = calendar.ordinality(of: .day, in: .year, for: self) ?? 0
        return String(format: "%04d-%03d", year, day)
    }

    var julianDate: Double {
        timeIntervalSince1970 / 86_400 + 2_440_587.5
    }

    var modifiedJulianDate: Double {
        julianDate - 2_400_000.5
    }

    var mayaLongCount: String {
        // Uses the widely adopted GMT correlation constant of 584,283 days.
        var remainingDays = Int(floor(julianDate + 0.5)) - 584_283
        let baktun = remainingDays / 144_000
        remainingDays %= 144_000
        let katun = remainingDays / 7_200
        remainingDays %= 7_200
        let tun = remainingDays / 360
        remainingDays %= 360
        let uinal = remainingDays / 20
        let kin = remainingDays % 20
        return "\(baktun).\(katun).\(tun).\(uinal).\(kin)"
    }

    var marsTime: String {
        // NASA Mars24 uses Terrestrial Time. TAI−UTC has been 37 seconds since 2017.
        let julianDateTerrestrialTime = julianDate + (37 + 32.184) / 86_400
        let marsSolDate = (julianDateTerrestrialTime - 2_405_522.0028779) / 1.0274912517
        let coordinatedMarsHours = marsSolDate.truncatingRemainder(dividingBy: 1) * 24
        let hours = Int(coordinatedMarsHours)
        let minutes = Int((coordinatedMarsHours - Double(hours)) * 60)
        return String(format: "MSD %.5f · MTC %02d:%02d", marsSolDate, hours, minutes)
    }

    var greenwichSiderealTime: String {
        let hoursSinceJ2000 = 18.697374558 + 24.06570982441908 * (julianDate - 2_451_545)
        let normalizedHours = hoursSinceJ2000.truncatingRemainder(dividingBy: 24) +
            (hoursSinceJ2000 < 0 ? 24 : 0)
        let totalSeconds = Int(normalizedHours * 3_600) % 86_400
        return String(
            format: "%02d:%02d:%02d GST",
            totalSeconds / 3_600,
            (totalSeconds / 60) % 60,
            totalSeconds % 60
        )
    }
    
  
    
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
