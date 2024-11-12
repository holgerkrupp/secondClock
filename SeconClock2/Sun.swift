//
//  Sun.swift
//  Codiad
//
//  Created by Huw Rowlands on 26.1.2016.
//  Copyright © 2016 Huw Rowlands. All rights reserved.
//
import Foundation
import CoreLocation

let SOLAR_DEGREES_PER_HOUR = 15.0

struct Sun {
    let dayOfYear: Double
    
    var longitude: Double {
        let solarMeanAnomaly = (0.9856 * dayOfYear) - 3.289
        
        let solarLongitudeApprox = solarMeanAnomaly + (1.916 * sin(solarMeanAnomaly.radians)) +
        (0.020 * sin(2 * solarMeanAnomaly.radians)) + 282.634
        
        return solarLongitudeApprox.truncatingRemainder(dividingBy: 360)
    }
    
    var rightAscension: Double {
        let x = 0.91764 * tan(longitude.radians)
        var solarRightAscensionApprox = atan(x).degrees
        
        let LQuadrant  = (floor(longitude                 / 90.0)) * 90
        let RAQuadrant = (floor(solarRightAscensionApprox / 90.0)) * 90
        
        solarRightAscensionApprox = solarRightAscensionApprox + (LQuadrant - RAQuadrant)
        
        return solarRightAscensionApprox / SOLAR_DEGREES_PER_HOUR
    }
    
    var declination: (sin: Double, cos: Double) {
        let s = 0.39782 * sin(longitude.radians)
        let c = cos(asin(s))
        
        return (s, c)
    }
    
    func localHourAngleCosine(_ zenith: Zenith, latitude: Double) -> Double {
        let zenithCosine = cos(zenith.rawValue.radians)
        
        return (zenithCosine -
                (declination.sin * sin(latitude.radians))) /
        (declination.cos * cos(latitude.radians))
    }



func localHourAngleCosine(zenith: Zenith, latitude: Double) -> Double {
    let zenithCosine = cos(zenith.rawValue.radians)
    
    return (zenithCosine -
            (declination.sin * sin(latitude.radians))) /
    (declination.cos * cos(latitude.radians))
}
}

// The usual one is 'Official'.

enum Zenith: Double {
    case official     = 90.8333333333
    case civil        = 96.0
    case nautical     = 102.0
    case astronomical = 108.0
}

//helpful maths functions
extension Double {
    public var radians: Double { return self * Double.pi / 180 }
    public var degrees: Double { return self * 180 / Double.pi }
}


