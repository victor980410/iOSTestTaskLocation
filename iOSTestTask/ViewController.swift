//
//  ViewController.swift
//  iOSTestTask
//
//  Created by Victor Semeniuk on 6/19/19.
//  Copyright © 2019 Victor Semeniuk. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let locationManager: CLLocationManager = CLLocationManager()
    var currentLocation: CLLocation? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.locationManager.delegate = self
        self.titleLabel.text = "Your address: "
        self.addressLabel.text = ""
        self.activityIndicator.startAnimating()
        
        if !CLLocationManager.locationServicesEnabled() {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestLocation()
        
        mapView.showsUserLocation = true
        let timer = Timer.init(timeInterval: 20, target: self, selector: #selector(updateLocation), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
    }
    
    @objc func updateLocation() {
        DispatchQueue.main.async { [weak self] in
            self?.locationManager.requestLocation()
        }
    }
    
    func updateAddress() {
        self.activityIndicator.isHidden = false
        self.activityIndicator.startAnimating()
        self.addressLabel.text = ""
        if let currentLocation = self.currentLocation {
            self.requestAddress(lat: currentLocation.coordinate.latitude, lon: currentLocation.coordinate.longitude) { [weak self] result in
                DispatchQueue.main.async {
                    self?.activityIndicator.stopAnimating()
                    self?.activityIndicator.isHidden = true
                    self?.addressLabel.text = result
                }
            }
        }
    }
    
    func requestAddress(lat: Double, lon: Double, onComplete: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://nominatim.openstreetmap.org/reverse.php?format=json&lat=\(lat)&lon=\(lon)") else { return }
        URLSession.shared.dataTask(with: url) {(data, response, error) in
            guard let data = data else { return onComplete(nil) }
            let result: AddressResponse? = data.decodeFromJson()
            onComplete(result?.address)
        }.resume()
    }
}

extension ViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last{
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            self.currentLocation = location
            self.mapView.setRegion(region, animated: true)
            self.mapView.setCenter(center, animated: true)
            self.updateAddress()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}


struct AddressResponse : Decodable {
    let address: String
    
    enum CodingKeys: String, CodingKey {
        case address = "display_name"
    }
}

extension Data {
    func decodeFromJson<T: Decodable>() -> T? {
        return try? JSONDecoder().decode(T.self, from: self)
    }
}
