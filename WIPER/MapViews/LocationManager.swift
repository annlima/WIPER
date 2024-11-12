import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus?
    private let locationManager = CLLocationManager()
    @Published var currentLocation: EquatableLocation?
    @Published var speed: Double = 0.0 {
        didSet {
            // Log speed here
            
        }
    } // Speed in km/h
    private var lastLocation: CLLocation?
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
        
        // Use only actual speed from device
        self.speed = max(newLocation.speed * 3.6, 0.0) // Convert m/s to km/h and ensure non-negative
        
        // Update current location for route drawing and relocation
        currentLocation = EquatableLocation(coordinate: newLocation.coordinate, speed: self.speed)
        
        // Calculate speed using previous location and time
        if let lastLocation = lastLocation, let lastUpdateTime = lastUpdateTime {
            let distance = newLocation.distance(from: lastLocation) // Distance in meters
            let timeInterval = newLocation.timestamp.timeIntervalSince(lastUpdateTime) // Time in seconds
            
            if timeInterval > 0 {
                let speedInMetersPerSecond = distance / timeInterval
                self.speed = max(speedInMetersPerSecond * 3.6, 0.0) // Convert to km/h and ensure non-negative
            }
        }
        
        // Update last location and time
        self.lastLocation = newLocation
        self.lastUpdateTime = newLocation.timestamp
    }
}
