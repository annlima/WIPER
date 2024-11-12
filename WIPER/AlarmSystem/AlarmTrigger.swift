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
        
        // Ignore alarm if speed is below 15 km/h
        if currentSpeed < 15 {
            print("Speed below threshold for alarm triggering.")
            return false
        }
        
        // Determine road condition based on visibility
        let condition = (visibility < visibilityThreshold) ? "wet" : "dry"
        
        // Find the closest speed category, rounding to the nearest multiple of 10
        let roundedSpeed = Int((currentSpeed / 10).rounded() * 10)
        guard let closestSpeed = getClosestSpeedKey(forSpeed: roundedSpeed),
              let stoppingDistance = getStoppingDistance(forSpeed: closestSpeed, condition: condition) else {
            return false
        }
        
        // Debug messages
        print("Speed: \(currentSpeed) km/h, Stopping distance for \(closestSpeed) km/h in \(condition) condition: \(stoppingDistance) meters")
        print("Object distance: \(objectDistance) meters")
        
        // Trigger alarm if distance is less than or equal to stopping distance
        return objectDistance <= stoppingDistance
    }

}

var audioPlayer: AVAudioPlayer?

// Function to Check and Trigger Alarm
func checkAndTriggerAlarm(objectDetected: Bool, objectDistance: Double, locationManager: LocationManager, visibility: Double) {
    // Simulación de velocidad si está en modo de prueba
    let simulatedSpeed = locationManager.speed
    
    let alarmSystem = AlarmSystem(
        objectDetected: objectDetected,
        objectDistance: objectDistance,
        currentSpeed: simulatedSpeed,
        visibility: visibility
    )
    
    if alarmSystem.shouldTriggerAlarm() {
        print("Alarma activada: Objeto a \(objectDistance) metros con velocidad \(simulatedSpeed) km/h")
        configureAudioSessionForPlayback()
        AlarmManager.shared.emitAlarmSound() // Emite el sonido de alarma
    } else {
        print("Alarma no activada: Distancia \(objectDistance) metros, velocidad \(simulatedSpeed) km/h, no dentro de rango")
    }
}

import AVFoundation

func configureAudioSessionForPlayback() {
    let audioSession = AVAudioSession.sharedInstance()
    
    do {
        try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try audioSession.setActive(true)
        print("Audio session configured for playback.")
    } catch {
        print("Failed to set audio session category and activate it: \(error)")
    }
}


class AlarmManager {
    static let shared = AlarmManager()
    var audioPlayer: AVAudioPlayer?
    
    func emitAlarmSound() {
        guard let soundURL = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3") else {
            print("Sound file not found in bundle.")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
        } catch {
            print("Error: Could not play alarm sound: \(error)")
        }
    }
}




