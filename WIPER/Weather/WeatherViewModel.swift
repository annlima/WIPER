//
//  WeatherViewModel.swift
//  WIPER
//
//  Created by Dicka J. Lezama on 17/10/24.
//

import SwiftUI
import WeatherKit
import CoreLocation

@MainActor
class WeatherViewModel: ObservableObject {
    @Published var visibilityCategory: String = ""
    
    private var weatherService = WeatherService()
    
    // Function to categorize visibility as Good or Bad (under 100 meters is Bad --> use wet conditions threshold for alarm system)
    func categorizeVisibility(visibility: Measurement<UnitLength>) -> String {
        let visibilityInMeters = visibility.converted(to: .meters).value
        
        if visibilityInMeters < 100 {
            return "Bad Visibility"
        } else {
            return "Good Visibility"
        }
    }
    
    // Fetch weather data using CLLocationCoordinate2D from the LocationManager
    func fetchWeatherData(for coordinates: CLLocationCoordinate2D) async {
        let location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        
        do {
            let weather = try await weatherService.weather(for: location)
            
            // Directly access visibility (as it's not optional)
            self.visibilityCategory = categorizeVisibility(visibility: weather.currentWeather.visibility)
            
        } catch {
            print("Error fetching weather data: \(error)")
        }
    }
}
