//
//  AlarmTrigger.swift
//  WIPER
//
//  Created by Dicka J. Lezama on 04/11/24.
//

import Foundation
import AVFoundation
import SwiftUI
import CoreLocation

// Alarm System Struct
struct AlarmSystem {
    var objectDetected: Bool
    var objectDistance: Double
    var currentSpeed: Double // Speed in km/h obtained from Core Location
    var visibility: Double // Visibility in meters obtained from WeatherKit
    
    // Predefined stopping distances (in meters) for each speed category
    let stoppingDistances: [Int: [String: Double]] = [
        40: ["dry": 26, "wet": 30],
        50: ["dry": 35, "wet": 40],
        60: ["dry": 45, "wet": 50],
        70: ["dry": 56, "wet": 60],
        80: ["dry": 69, "wet": 75],
        90: ["dry": 83, "wet": 90],
        100: ["dry": 98, "wet": 105],
        110: ["dry": 113, "wet": 125]
    ]
    
    let visibilityThreshold: Double = 100.0 // Threshold for good/bad visibility
    
    func getStoppingDistance(forSpeed speed: Int, condition: String) -> Double? {
        return stoppingDistances[speed]?[condition]
    }
    
    func getClosestSpeedKey(forSpeed speed: Int) -> Int? {
        let availableSpeeds = Array(stoppingDistances.keys)
        return availableSpeeds.min(by: { abs($0 - speed) < abs($1 - speed) })
    }
    
    func shouldTriggerAlarm() -> Bool {
        guard objectDetected else { return false }
        
        // Determine road condition based on visibility
        let condition = (visibility < visibilityThreshold) ? "wet" : "dry"
        
        // Find the closest speed key
        let roundedSpeed = Int((currentSpeed / 10).rounded() * 10)
        guard let closestSpeed = getClosestSpeedKey(forSpeed: roundedSpeed),
              let stoppingDistance = getStoppingDistance(forSpeed: closestSpeed, condition: condition) else {
            return false // No valid stopping distance for this speed
        }
        
        // Check if object is within the stopping distance
        return objectDistance <= stoppingDistance
    }
}

var audioPlayer: AVAudioPlayer?

func emitAlarmSound() {
    guard let soundURL = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3") else { return }
    
    do {
        audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
        audioPlayer?.play()
    } catch {
        print("Error: Could not play alarm sound.")
    }
}

// Function to Check and Trigger Alarm
func checkAndTriggerAlarm(objectDetected: Bool, objectDistance: Double, locationManager: LocationManager, visibility: Double) {
    guard let currentSpeed = locationManager.currentLocation?.speed else {
        print("Current speed not available")
                return
    }
    let alarmSystem = AlarmSystem(
        objectDetected: objectDetected,
        objectDistance: objectDistance,
        currentSpeed: currentSpeed,
        visibility: visibility
    )
    
    if alarmSystem.shouldTriggerAlarm() {
        // Trigger sound if alarm is activated
        emitAlarmSound()
    }
}


