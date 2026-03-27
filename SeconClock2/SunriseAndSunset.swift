import Foundation
import CoreLocation

private enum Event {
    case sunrise
    case sunset
}

private extension TimeZone {
    var hoursfromGMT: Double {
        return Double(self.secondsFromGMT()) / (60 * 60)
    }
}

func longitudinalHour(_ longitude: CLLocationDegrees) -> Double {
    return longitude / SOLAR_DEGREES_PER_HOUR
}

extension Date {
    
    fileprivate func timeOfEvent(_ event: Event, location: CLLocation, zenith: Zenith) -> Date? {
        let cal = Calendar.current
        
        let dayOfYear = Double(cal.ordinality(of: .day, in: .year, for: self) ?? 0)
        
        let sun = Sun(dayOfYear: dayOfYear)
        
        //guess for rise or set
        let guess = (event == .sunrise) ? 6.0 : 18.0
        let approxT = ((guess - longitudinalHour(location.coordinate.longitude)) / 24.0) + dayOfYear
        
        //7a.
        let cosHour = sun.localHourAngleCosine(zenith, latitude: location.coordinate.latitude)
        
        guard (cosHour < 1) && (cosHour > -1) else {
            return nil
        }
        
        //7b
        let multiplier = (event == .sunrise) ? -1.0 : 1.0
        let hour = (acos(cosHour).degrees * multiplier) / 15
        
        //8
        let T = (hour + sun.rightAscension - (0.06571 * approxT) - 6.622)
        
        //9 -- coerce into UTC while preserving day rollover.
        let rawUTC = T - longitudinalHour(location.coordinate.longitude)
        let dayAdjustment = Int(floor(rawUTC / 24.0))
        var normalizedUTC = rawUTC.truncatingRemainder(dividingBy: 24)
        if normalizedUTC < 0 {
            normalizedUTC += 24
        }

        let baseDay = cal.startOfDay(for: self)
        guard let adjustedBaseDay = cal.date(byAdding: .day, value: dayAdjustment, to: baseDay) else {
            return nil
        }

        //coerce into NSDate
        var dateComponents = cal.dateComponents([.day, .month, .year], from: adjustedBaseDay)
        dateComponents.hour   = Int(normalizedUTC)
        dateComponents.minute = Int((normalizedUTC * 60).truncatingRemainder(dividingBy: 60))
        dateComponents.second = Int((normalizedUTC * 3600).truncatingRemainder(dividingBy: 60))
        dateComponents.timeZone = TimeZone(identifier: "UTC")
        
        return cal.date(from: dateComponents)
    }
    
    func sunrise(_ location: CLLocation, zenith: Zenith) -> Date? {
        return timeOfEvent(.sunrise, location: location, zenith: .official)
    }
    
    func sunset(_ location: CLLocation, zenith: Zenith) -> Date? {
        return timeOfEvent(.sunset, location: location, zenith: .official)
    }
    
    func sunrise(_ location: CLLocation) -> Date? {
        return sunrise(location, zenith: .official)
    }
    
    func sunset(_ location: CLLocation) -> Date? {
        return sunset(location, zenith: .official)
    }
    
}
