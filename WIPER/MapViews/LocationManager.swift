import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus?
    private let locationManager = CLLocationManager()
    @Published var currentLocation: EquatableLocation?
    @Published var speed: Double = 0.0 // Velocidad en km/h
    @Published var lastLocation: CLLocation?
    var simulateSpeed: Double? // Añade esta propiedad opcional para simular la velocidad
    private var lastUpdateTime: Date?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        checkAuthorizationStatus()
        locationManager.startUpdatingLocation()
    }

    func checkAuthorizationStatus() {
        authorizationStatus = locationManager.authorizationStatus
        
        switch locationManager.authorizationStatus {
        case .restricted, .denied:
            print("Location access denied or restricted")
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
            print("Location services are not enabled")
        }
    }

    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            startLocationUpdates()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        if let simulatedSpeed = simulateSpeed {
                   self.speed = simulatedSpeed
               } else {
                   self.speed = newLocation.speed * 3.6 // Convertir m/s a km/h
               }
        
        // Actualiza la ubicación actual para pintar la ruta y relocalizar
        currentLocation = EquatableLocation(coordinate: newLocation.coordinate, speed: self.speed)
        
        // Calcular la velocidad usando la ubicación y tiempo anterior
        if let lastLocation = lastLocation, let lastUpdateTime = lastUpdateTime {
            let distance = newLocation.distance(from: lastLocation) // Distancia en metros
            let timeInterval = newLocation.timestamp.timeIntervalSince(lastUpdateTime) // Tiempo en segundos
            
            if timeInterval > 0 {
                let speedInMetersPerSecond = distance / timeInterval
                self.speed = speedInMetersPerSecond * 3.6 // Convertir a km/h
            }
        }
        
        // Actualiza la última ubicación y tiempo
        self.lastLocation = newLocation
        self.lastUpdateTime = newLocation.timestamp
    }
}
