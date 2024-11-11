//
//  EquatableLocation.swift
//  WIPER
//
//  Created by Andrea Lima Blanca on 23/10/24.
//

import Foundation
import CoreLocation

struct EquatableLocation: Equatable {
    var coordinate: CLLocationCoordinate2D
    var speed: Double

    static func == (lhs: EquatableLocation, rhs: EquatableLocation) -> Bool {
        return lhs.coordinate.latitude == rhs.coordinate.latitude &&
               lhs.coordinate.longitude == rhs.coordinate.longitude
    }
}
