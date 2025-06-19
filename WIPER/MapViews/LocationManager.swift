import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var isAuthorized: Bool = false
    private let locationManager = CLLocationManager()
    @Published var currentLocation: EquatableLocation?
    @Published var speed: Double = 0.0 {
        didSet {
            
        }
    }

    @Published var lastLocation: CLLocation?

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
        case .notDetermined:
            print("Location not determined")
        @unknown default:
            break
        }
    }

    func requestLocationAuthorization() {
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                DispatchQueue.main.async {
                    self.locationManager.requestWhenInUseAuthorization()
                }
            } else {
                print("Location services are not enabled")
            }
        }
    }
    
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        isAuthorized = manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways

        if isAuthorized {
            startLocationUpdates()
        } else {
            print("Location access denied or restricted")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }


        self.speed = max(newLocation.speed * 3.6, 0.0)
        
        currentLocation = EquatableLocation(coordinate: newLocation.coordinate, speed: self.speed)
        
        if let lastLocation = lastLocation, let lastUpdateTime = lastUpdateTime {
            let distance = newLocation.distance(from: lastLocation)
            let timeInterval = newLocation.timestamp.timeIntervalSince(lastUpdateTime)
            
            if timeInterval > 0 {
                let speedInMetersPerSecond = distance / timeInterval
                self.speed = max(speedInMetersPerSecond * 3.6, 0.0)
            }
        }
        
        self.lastLocation = newLocation
        self.lastUpdateTime = newLocation.timestamp
    }
}
