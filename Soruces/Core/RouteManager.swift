//
//  RouteManager.swift
//  MapNavigationDemo
//
//  Created by Arron Stothart on 12/11/2024.
//

import Foundation
import MapKit

class RouteManager: NSObject, MKMapViewDelegate {
    private var currentRoute: MKRoute?
    var routeOverlay: MKPolyline?
    private let mapView: MKMapView
    private var currentStepIndex: Int = 0
    
    var onRouteUpdated: ((MKRoute) -> Void)?
    var onStepUpdated: ((NavigationStep) -> Void)?
    var onRouteDeviation: (() -> Void)?
    var onDistanceUpdated: ((CLLocationDistance) -> Void)?
    
    private var routeProgress: RouteProgress?
    private let routeCorridorWidth: Double = 25 // TODO: Tune
    
    private var lastProgressUpdate = Date()
    private let progressUpdateInterval: TimeInterval = 0.1 // Update every 100ms
    
    // New property to store live progress
    private var liveProgress: LiveProgress?
    private var displayLink: CADisplayLink?
    
    // Add new property to track traversed path
    private var traversedPath: MKPolyline?
    private var traversedCoordinates: [CLLocationCoordinate2D] = []
    
    struct NavigationStep {
        let instruction: String
        let notice: String?
        let distance: CLLocationDistance
        let transportType: MKDirectionsTransportType
        let eta: Date
        let remainingDistance: CLLocationDistance
        let remainingTime: TimeInterval
        
        var formattedDistance: String {
            if distance < 1000 {
                return "\(Int(distance))m"
            } else {
                return String(format: "%.1f km", distance/1000)
            }
        }
        
        var formattedETA: String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: eta)
        }
    }
    
    struct RouteProgress {
        let route: MKRoute
        var currentStepIndex: Int
        var distanceRemaining: CLLocationDistance
        var timeRemaining: TimeInterval
        
        var currentStep: MKRoute.Step {
            route.steps[currentStepIndex]
        }
        
        var nextStep: MKRoute.Step? {
            guard currentStepIndex + 1 < route.steps.count else { return nil }
            return route.steps[currentStepIndex + 1]
        }
    }
    
    struct LiveProgress {
        var currentLocation: CLLocation
        var distanceToNextStep: CLLocationDistance
        var totalRemainingDistance: CLLocationDistance
        var totalRemainingTime: TimeInterval
        var currentStep: MKRoute.Step
        var nextStep: MKRoute.Step?
    }
    
    init(mapView: MKMapView) {
       self.mapView = mapView
       super.init()
       self.mapView.delegate = self
       setupDisplayLink()
   }
    
    private func setupDisplayLink() {
        displayLink = CADisplayLink(target: self, selector: #selector(updateDisplay))
        displayLink?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60)
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc private func updateDisplay() {
        guard let progress = liveProgress else { return }
        
        // Create navigation step with live data
        let step = NavigationStep(
            instruction: progress.currentStep.instructions,
            notice: progress.currentStep.notice,
            distance: progress.distanceToNextStep,
            transportType: currentRoute?.transportType ?? .automobile,
            eta: Date().addingTimeInterval(progress.totalRemainingTime),
            remainingDistance: progress.totalRemainingDistance,
            remainingTime: progress.totalRemainingTime
        )
        
        onStepUpdated?(step)
    }
    
    func calculateRoute(
        source: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        transportType: MKDirectionsTransportType = .automobile,
        completion: ((MKRoute) -> Void)? = nil
    ) {
        // TODO: Implement multi-segment routing for Roadwise project
        // Current MapKit API (iOS 18) doesn't support waypoints directly.
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = transportType
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] response, error in
            guard let route = response?.routes.first else { return }
            self?.displayRoute(route)
            completion?(route)
        }
    }

    private func handleRouteDeviation() {
        // Clear traversed path when rerouting
        traversedCoordinates = []
        if let existing = traversedPath {
            mapView.removeOverlay(existing)
            traversedPath = nil
        }
        
        guard let currentLocation = mapView.userLocation.location,
                let route = currentRoute else { return }
        
        let destinationCoordinate = route.polyline.points()[route.polyline.pointCount - 1].coordinate

        calculateRoute(
            source: currentLocation.coordinate,
            destination: destinationCoordinate,
            transportType: route.transportType
        )

        onRouteDeviation?()
    }
    
    private func displayRoute(_ route: MKRoute) {
        // Remove existing overlays
        if let existing = routeOverlay {
            mapView.removeOverlay(existing)
        }
        if let existing = traversedPath {
            mapView.removeOverlay(existing)
        }
        
        currentRoute = route
        routeOverlay = route.polyline
        
        // Add the main route first (so it appears below the traversed path)
        mapView.addOverlay(route.polyline)
        
        // Reset traversed path when displaying new route
        traversedCoordinates = []
        
        onRouteUpdated?(route)
    }
    
    func updateProgress(for location: CLLocation) {
        guard let route = currentRoute else { return }
        
        // Add current location to traversed path
        traversedCoordinates.append(location.coordinate)
        
        // Update traversed path overlay
        if traversedCoordinates.count >= 2 {
            if let existing = traversedPath {
                mapView.removeOverlay(existing)
            }
            traversedPath = MKPolyline(coordinates: traversedCoordinates, count: traversedCoordinates.count)
            if let traversedPath = traversedPath {
                // Remove and re-add the main route to ensure it's below the traversed path
                if let routeOverlay = routeOverlay {
                    mapView.removeOverlay(routeOverlay)
                    mapView.addOverlay(routeOverlay) // Add main route first
                }
                mapView.addOverlay(traversedPath)    // Add traversed path on top
            }
        }
        
        // Find closest point and check corridor
        let closestPoint = findClosestPoint(location: location, onRoute: route.polyline)
        let distanceFromRoute = location.distance(from: CLLocation(
            latitude: closestPoint.coordinate.latitude,
            longitude: closestPoint.coordinate.longitude
        ))
        
        if distanceFromRoute > routeCorridorWidth {
            handleRouteDeviation()
            return
        }
        
        // Calculate all the live metrics
        let (currentStepIndex, distanceToNext) = calculateStepProgress(location: location, route: route)
        let (remainingDistance, remainingTime) = calculateRemainingProgress(
            fromLocation: location,
            startingAtStep: currentStepIndex,
            route: route
        )
        
        // Update live progress
        liveProgress = LiveProgress(
            currentLocation: location,
            distanceToNextStep: distanceToNext,
            totalRemainingDistance: remainingDistance,
            totalRemainingTime: remainingTime,
            currentStep: route.steps[currentStepIndex],
            nextStep: currentStepIndex + 1 < route.steps.count ? route.steps[currentStepIndex + 1] : nil
        )
    }
    
    private func calculateStepProgress(location: CLLocation, route: MKRoute) -> (stepIndex: Int, distanceToNext: CLLocationDistance) {
        // Find which step we're on and distance to next maneuver
        var minDistance = Double.infinity
        var currentStepIndex = 0
        
        for (index, step) in route.steps.enumerated() {
            let stepPoints = Array(UnsafeBufferPointer(
                start: step.polyline.points(),
                count: step.polyline.pointCount
            ))
            
            for point in stepPoints {
                let distance = location.distance(from: CLLocation(
                    latitude: point.coordinate.latitude,
                    longitude: point.coordinate.longitude
                ))
                if distance < minDistance {
                    minDistance = distance
                    currentStepIndex = index
                }
            }
        }
        
        // Calculate distance to next maneuver
        let currentStep = route.steps[currentStepIndex]
        let stepEndPoint = currentStep.polyline.points()[currentStep.polyline.pointCount - 1]
        let distanceToNext = location.distance(from: CLLocation(
            latitude: stepEndPoint.coordinate.latitude,
            longitude: stepEndPoint.coordinate.longitude
        ))
        
        return (currentStepIndex, distanceToNext)
    }
    
    private func calculateRemainingProgress(
        fromLocation location: CLLocation,
        startingAtStep stepIndex: Int,
        route: MKRoute
    ) -> (distance: CLLocationDistance, time: TimeInterval) {
        var remainingDistance: CLLocationDistance = 0
        
        // Calculate remaining distance for all future steps
        for (index, step) in route.steps.enumerated() where index >= stepIndex {
            if index == stepIndex {
                // For current step, calculate from current location
                let stepEndPoint = step.polyline.points()[step.polyline.pointCount - 1]
                remainingDistance += location.distance(from: CLLocation(
                    latitude: stepEndPoint.coordinate.latitude,
                    longitude: stepEndPoint.coordinate.longitude
                ))
            } else {
                // For future steps, use full distance
                remainingDistance += step.distance
            }
        }
        
        // Calculate remaining time based on the ratio of remaining distance to total route distance
        let remainingTime = route.expectedTravelTime * (remainingDistance / route.distance)
        
        return (remainingDistance, remainingTime)
    }
    
    private func findClosestPoint(location: CLLocation, onRoute polyline: MKPolyline) -> MKMapPoint {
        // TODO: Better implementation
        let points = polyline.points()
        let pointCount = polyline.pointCount
        
        var closestPoint = MKMapPoint(location.coordinate)
        var minDistance = Double.infinity
        
        for i in 0..<(pointCount - 1) {
            let p1 = points[i]
            let p2 = points[i + 1]
            
            let projection = closestPointOnSegment(
                point: MKMapPoint(location.coordinate),
                segmentStart: p1,
                segmentEnd: p2
            )
            
            let distance = projection.distance(to: MKMapPoint(location.coordinate))
            if distance < minDistance {
                minDistance = distance
                closestPoint = projection
            }
        }
        
        return closestPoint
    }

    private func closestPointOnSegment(point: MKMapPoint, segmentStart: MKMapPoint, segmentEnd: MKMapPoint) -> MKMapPoint {
         // TODO: Better implementation
        let dx = segmentEnd.x - segmentStart.x
        let dy = segmentEnd.y - segmentStart.y
        
        if dx == 0 && dy == 0 {
            return segmentStart
        }
        
        let t = ((point.x - segmentStart.x) * dx + (point.y - segmentStart.y) * dy) / (dx * dx + dy * dy)
        
        let tClamped = max(0, min(1, t))
        
        return MKMapPoint(
            x: segmentStart.x + tClamped * dx,
            y: segmentStart.y + tClamped * dy
        )
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            
            if polyline === traversedPath {
                // Dimmer blue for traversed path
                renderer.strokeColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 0.5)
            } else {
                // Regular blue for remaining route
                renderer.strokeColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)
            }
            
            renderer.lineWidth = 12
            renderer.lineCap = .round
            renderer.lineJoin = .round
            
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            let puckView = MKAnnotationView(annotation: annotation, reuseIdentifier: "userLocation")
            
            // Create outer blue circle (accuracy radius)
            let outerCircle = UIView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
            outerCircle.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            outerCircle.layer.cornerRadius = 20
            
            // Create inner blue circle (location puck)
            let innerCircle = UIView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
            innerCircle.backgroundColor = UIColor.systemBlue
            innerCircle.layer.cornerRadius = 12
            
            // Add white border to inner circle
            innerCircle.layer.borderWidth = 3
            innerCircle.layer.borderColor = UIColor.white.cgColor
            
            // Add shadow to inner circle
            innerCircle.layer.shadowColor = UIColor.black.cgColor
            innerCircle.layer.shadowOffset = CGSize(width: 0, height: 2)
            innerCircle.layer.shadowRadius = 4
            innerCircle.layer.shadowOpacity = 0.25
            
            // Set up view hierarchy
            puckView.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
            puckView.addSubview(outerCircle)
            puckView.addSubview(innerCircle)
            
            // Center both circles
            outerCircle.center = CGPoint(x: puckView.frame.width / 2, y: puckView.frame.height / 2)
            innerCircle.center = CGPoint(x: puckView.frame.width / 2, y: puckView.frame.height / 2)
            
            return puckView
        }
        return nil
    }
    
    deinit {
        displayLink?.invalidate()
    }
}
