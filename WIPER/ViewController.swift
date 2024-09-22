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
        // Do any additional setup after loading the view.
        
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        if (CLLocationManager.locationServicesEnabled()){
            locationManager.requestLocation()
            locationManager.startUpdatingLocation()
        }
        
        textField_Address.delegate = self
        myMap.delegate = self
    }
    
    @IBAction func DirectionsButton(_ sender: Any) {
        myGeoCoder.geocodeAddressString(textField_Address.text ?? "" ){(placemark, error) in
            self.processResponse(withPlacemarks: placemark, error: error)
        }
    }
    
    //process the request coming from the geocoder
    func processResponse(withPlacemarks placemarks: [CLPlacemark]?, error: Error?){
        if let error = error {
            print("Error fetching the coordinates (\(error)")
        }
        
        else {
            //fetch coordinates from placemarks
            var location: CLLocation?
            if let placemarks = placemarks, placemarks.count > 0 {
                location = placemarks.first?.location
            }
            
            if let location = location {
                let coordinate = location.coordinate
                
                //request source, destination and mode of travel (default as automobile in this case)
                
                let request = MKDirections.Request()
                request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: locationManager.location?.coordinate.latitude ?? 0.0, longitude: locationManager.location?.coordinate.longitude ?? 0.0)))
                request.destination = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)))
                request.transportType = .automobile
                request.requestsAlternateRoutes = true
                
                //plotting requests on the map
                let directions = MKDirections(request: request)
                directions.calculate{response, error in
                    guard let directionsResponse = response else {return}
                    
                    for route in directionsResponse.routes {
                        self.myMap.addOverlay(route.polyline)
                        self.myMap.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                    }
                }
                
                //adding pin
                let addressPin = MKPointAnnotation()
                addressPin.coordinate = coordinate
                addressPin.title = textField_Address.text
                addressPin.subtitle = "Destination"
                
                myMap.addAnnotation(addressPin)
            }
        }
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

