//
//  ViewController.swift
//  Maps2
//
//  Created by MacBookAir on 05/09/23.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController , CLLocationManagerDelegate, UITextFieldDelegate, MKMapViewDelegate{
    @IBOutlet weak var myMap: MKMapView!
    
    @IBOutlet weak var textField_Address: UITextField!
    
    //transfor address to coordinates
    var myGeoCoder = CLGeocoder()
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if (CLLocationManager.locationServicesEnabled()) {
            locationManager.requestLocation()
            locationManager.startUpdatingLocation()
        }
        
        textField_Address.delegate = self
        myMap.delegate = self

        // Configuración de un zoom inicial adecuado
        let initialLocation = CLLocationCoordinate2D(latitude: 19.03793, longitude: -98.20346)
        let initialRegion = MKCoordinateRegion(center: initialLocation, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        myMap.setRegion(initialRegion, animated: true)
    }

    func processResponse(withPlacemarks placemarks: [CLPlacemark]?, error: Error?) {
        if let error = error {
            print("Error fetching the coordinates (\(error)")
            return
        }
        
        // Fetch coordinates from placemarks
        guard let location = placemarks?.first?.location else { return }
        let coordinate = location.coordinate
        
        // Request source, destination, and mode of travel (default as automobile)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: locationManager.location?.coordinate ?? CLLocationCoordinate2D()))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        request.transportType = .automobile
        request.requestsAlternateRoutes = true
        
        // Plotting requests on the map
        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let directionsResponse = response else { return }
            
            // Remove any existing overlays before adding new one
            self.myMap.removeOverlays(self.myMap.overlays)
            
            for route in directionsResponse.routes {
                self.myMap.addOverlay(route.polyline)
                
                // Ajustar el zoom para que la ruta sea visible
                self.myMap.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: true)
            }
        }
        
        // Adding pin for destination
        let addressPin = MKPointAnnotation()
        addressPin.coordinate = coordinate
        addressPin.title = textField_Address.text
        addressPin.subtitle = "Destination"
        
        myMap.addAnnotation(addressPin)
    }

    
    //render the map -mkoverlay renderer
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(polyline: overlay as! MKPolyline)
        renderer.strokeColor = .orange
        renderer.lineWidth = 4.0
        renderer.alpha = 1.0
        return renderer
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //locations is a set of arrays, picking the first item of the array and assigning it to the user's location/
        if let userLocation = locations.first {
            manager.stopUpdatingLocation()
            
            let coordinates = CLLocationCoordinate2D(latitude: locationManager.location?.coordinate.latitude ?? 0.0, longitude: locationManager.location?.coordinate.longitude ?? 0.0)
            
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1) //Altitude for the map - zoom up = higher value
            
            let region = MKCoordinateRegion(center: coordinates, span: span)
            
            myMap.setRegion(region, animated: true)
            
            //adding pin
            let myPin = MKPointAnnotation()
            myPin.coordinate = coordinates
            myPin.title = "You're here"
            
            myMap.addAnnotation(myPin)
        }
            
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus{
        case .authorizedAlways:
            return
        case .authorizedWhenInUse:
            return
        case .denied:
            return
        case .restricted:
            locationManager.requestWhenInUseAuthorization()
            return
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error){
        print(error)
    }
    
}

