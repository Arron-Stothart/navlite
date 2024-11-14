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
    
    init(mapView: MKMapView) {
       self.mapView = mapView
       super.init()
       self.mapView.delegate = self
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
        if let existing = routeOverlay {
            mapView.removeOverlay(existing)
        }
        
        currentRoute = route
        routeOverlay = route.polyline
        mapView.addOverlay(route.polyline)

        onRouteUpdated?(route)
    }
    
    func updateProgress(for location: CLLocation) {
        guard let route = currentRoute else { return }
        guard let progress = routeProgress else {
            // Initialise progress when starting navigation
            routeProgress = RouteProgress(
                route: route,
                currentStepIndex: 0,
                distanceRemaining: route.distance,
                timeRemaining: route.expectedTravelTime
            )
            return
        }
        
        // Find closest point on route and check if within corridor
        let closestPoint = findClosestPoint(location: location, onRoute: route.polyline)
        
        let distanceFromRoute = location.distance(from: CLLocation(
            latitude: closestPoint.coordinate.latitude,
            longitude: closestPoint.coordinate.longitude
        ))
        
        if distanceFromRoute > routeCorridorWidth {
            handleRouteDeviation()
            return
        }
        
        updateCurrentStep(location: location, progress: &routeProgress!)
        updateRemainingProgress(location: location, progress: &routeProgress!)
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
    
    private func updateCurrentStep(location: CLLocation, progress: inout RouteProgress) {
        let currentStep = progress.currentStep
        let points = Array(UnsafeBufferPointer(start: currentStep.polyline.points(), count: currentStep.polyline.pointCount))
        let stepEndPoint = CLLocation(
            latitude: points.last!.coordinate.latitude,
            longitude: points.last!.coordinate.longitude
        )
        
        if location.distance(from: stepEndPoint) < 20 { // TODO: Tune
            if progress.currentStepIndex < progress.route.steps.count - 1 {
                progress.currentStepIndex += 1
                onStepUpdated?(createNavigationStep(from: progress))
            }
        }
    }

    private func updateRemainingProgress(location: CLLocation, progress: inout RouteProgress) {
        let remainingSteps = progress.route.steps.suffix(from: progress.currentStepIndex)
        
        let points = Array(UnsafeBufferPointer(
            start: progress.currentStep.polyline.points(),
            count: progress.currentStep.polyline.pointCount
        ))
        
        // Calculate remaining distance using closest point to current location
        let closestPoint = findClosestPoint(location: location, onRoute: progress.currentStep.polyline)
        let distanceToStepEnd = location.distance(from: CLLocation(
            latitude: points[points.count - 1].coordinate.latitude,
            longitude: points[points.count - 1].coordinate.longitude
        ))
        
        // Calculate remaining distance for all steps
        let remainingStepsDistance = remainingSteps.dropFirst().reduce(0) { sum, step in
            sum + step.distance
        }
        progress.distanceRemaining = distanceToStepEnd + remainingStepsDistance
        
        // Notify about distance update
        onDistanceUpdated?(distanceToStepEnd)
        
        // Calculate remaining time based on average speed
        let currentStepTime = progress.route.expectedTravelTime * (distanceToStepEnd / progress.currentStep.distance)
        let remainingStepsTime = remainingSteps.dropFirst().reduce(0) { sum, step in
            sum + (progress.route.expectedTravelTime * (step.distance / progress.route.distance))
        }
        progress.timeRemaining = currentStepTime + remainingStepsTime
    }
    
    private func createNavigationStep(from progress: RouteProgress) -> NavigationStep {
        return NavigationStep(
            instruction: progress.currentStep.instructions,
            notice: progress.currentStep.notice,
            distance: progress.currentStep.distance,
            transportType: progress.route.transportType,
            eta: Date().addingTimeInterval(progress.timeRemaining),
            remainingDistance: progress.distanceRemaining,
            remainingTime: progress.timeRemaining
        )
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            
            // Match Apple Maps colors
            renderer.strokeColor = UIColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0)  // Blue similar to Apple Maps
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
}
