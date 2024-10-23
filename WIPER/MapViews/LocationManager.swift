import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus?
    private let locationManager = CLLocationManager()
    @Published var currentLocation: EquatableLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        checkAuthorizationStatus()
    }

    func checkAuthorizationStatus() {
        authorizationStatus = locationManager.authorizationStatus
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            requestLocationAuthorization()
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
        if let location = locations.last {
            currentLocation = EquatableLocation(coordinate: location.coordinate)
        }
    }
}
