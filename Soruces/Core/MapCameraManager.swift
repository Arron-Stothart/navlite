//
//  MapCameraManager.swift
//  MapNavigationDemo
//
//  Created by Arron Stothart on 12/11/2024.
//

import Foundation
import MapKit

class MapCameraManager {
    private let mapView: MKMapView
    private var isFollowingUser = true
    private let navigationDistance: CLLocationDistance = 300 // TODO: Tune
    private let navigationPitch: CGFloat = 65 // TODO: Tune
    
    init(mapView: MKMapView) {
        self.mapView = mapView
    }
    
    func updateCamera(for location: CLLocation, heading: CLHeading?) {
        guard isFollowingUser else { return }
        
        let camera = MKMapCamera(
            lookingAtCenter: location.coordinate,
            fromDistance: navigationDistance,
            pitch: navigationPitch,
            heading: heading?.trueHeading ?? 0
        )
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.mapView.camera = camera
        }
    }
    
    func toggleFollowMode() {
        isFollowingUser.toggle()
    }
    
    func showRouteOverview(route: MKRoute, animated: Bool = true) {
        let region = route.polyline.boundingMapRect
        let insets = UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100)
        
        if animated {
            mapView.setVisibleMapRect(region, edgePadding: insets, animated: true)
        } else {
            mapView.setVisibleMapRect(region, edgePadding: insets, animated: false)
        }
        isFollowingUser = false
    }
}
