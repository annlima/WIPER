import Foundation
import CoreLocation
import WeatherKit
import Combine

class WeatherManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let weatherService = WeatherService()
    
    @Published var currentWeather: Weather? // Publica el clima para que las vistas puedan reaccionar a los cambios
    
    override init() {
        super.init()
        locationManager.delegate = self
        checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() {
        let authorizationStatus = locationManager.authorizationStatus
        
        switch authorizationStatus {
        case .notDetermined:
            requestLocationAuthorization()
        case .restricted, .denied:
            print("Acceso a la ubicación denegado o restringido")
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }

    func requestLocationAuthorization() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
        } else {
            print("Los servicios de ubicación no están habilitados")
        }
    }

    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            fetchWeather(for: location)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startLocationUpdates()
        }
    }

    func fetchWeather(for location: CLLocation) {
        Task {
            do {
                let weather = try await weatherService.weather(for: location)
                DispatchQueue.main.async {
                    self.currentWeather = weather
                    // Imprime la temperatura actual y las condiciones climáticas
                    let temperature = weather.currentWeather.temperature
                    let condition = weather.currentWeather.condition.description
                    print("Temperatura actual: \(temperature)")
                    print("Condición actual: \(condition)")
                }
            } catch {
                print("Error al obtener el clima: \(error.localizedDescription)")
            }
        }
    }
}
