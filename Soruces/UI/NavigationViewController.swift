//
//  NavigationViewController.swift
//  MapNavigationDemo
//
//  Created by Arron Stothart on 12/11/2024.
//

import Foundation
import MapKit

class NavigationViewController: UIViewController {
    private let mapView = MKMapView()
    private lazy var cameraManager = MapCameraManager(mapView: mapView)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        
        LocationManager.shared.startTracking()
        LocationManager.shared.onLocationUpdate = { [weak self] location in
            self?.handleLocationUpdate(location)
        }
        LocationManager.shared.onHeadingUpdate = { [weak self] heading in
            self?.handleHeadingUpdate(heading)
        }
    }
    
    private func setupMapView() {
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        mapView.showsUserLocation = true
    }
    
    private func handleLocationUpdate(_ location: CLLocation) {
        cameraManager.updateCamera(for: location, heading: nil)
    }
    
    private func handleHeadingUpdate(_ heading: CLHeading) {
        guard let currentLocation = LocationManager.shared.locationManager.location else {
            return
        }
        cameraManager.updateCamera(for: currentLocation, heading: heading)
    }
}
