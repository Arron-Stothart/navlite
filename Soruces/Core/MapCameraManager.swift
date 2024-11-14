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
    private let navigationDistance: CLLocationDistance = 500
    private let navigationPitch: CGFloat = 60
    private var lastHeading: Double = 0
    private var targetHeading: Double = 0
    private var displayLink: CADisplayLink?
    private let rotationDuration: TimeInterval = 0.5
    private var rotationStartTime: TimeInterval = 0
    private var rotationStartHeading: Double = 0
    private var isRotating = false
    
    init(mapView: MKMapView) {
        self.mapView = mapView
        setupDisplayLink()
    }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateRotation))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60)
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateRotation() {
        guard isRotating else { return }
        
        let currentTime = CACurrentMediaTime()
        let elapsed = currentTime - rotationStartTime
        let progress = min(elapsed / rotationDuration, 1.0)
        
        // Use smooth step interpolation for more natural movement
        let smoothProgress = progress * progress * (3 - 2 * progress)
        
        // Calculate the shortest rotation path
        var delta = targetHeading - rotationStartHeading
        if delta > 180 {
            delta -= 360
        } else if delta < -180 {
            delta += 360
        }
        
        let currentHeading = rotationStartHeading + delta * smoothProgress
        
        // Update camera with interpolated heading
        let camera = mapView.camera
        camera.heading = currentHeading
        mapView.camera = camera
        
        if progress >= 1.0 {
            isRotating = false
            lastHeading = targetHeading
        }
    }
    
    func updateCamera(for location: CLLocation, heading: Double?, animated: Bool = true) {
        guard isFollowingUser else { return }
        
        if let heading = heading {
            // Update target heading and start rotation if needed
            targetHeading = heading
            
            if !isRotating {
                rotationStartTime = CACurrentMediaTime()
                rotationStartHeading = lastHeading
                isRotating = true
            }
        }
        
        let camera = MKMapCamera(
            lookingAtCenter: location.coordinate,
            fromDistance: navigationDistance,
            pitch: navigationPitch,
            heading: lastHeading
        )
        
        if animated {
            UIView.animate(
                withDuration: 1.0,
                delay: 0,
                options: [.curveLinear],
                animations: {
                    // Only animate position and pitch, heading is handled separately
                    self.mapView.camera.centerCoordinate = camera.centerCoordinate
                    self.mapView.camera.pitch = camera.pitch
                    self.mapView.camera.altitude = camera.altitude
                }
            )
        } else {
            mapView.camera.centerCoordinate = camera.centerCoordinate
            mapView.camera.pitch = camera.pitch
            mapView.camera.altitude = camera.altitude
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
    
    deinit {
        displayLink?.invalidate()
    }
}
