//
//  NavigationViewController.swift
//  MapNavigationDemo
//
//  Created by Arron Stothart on 12/11/2024.
//

import Foundation
import MapKit
import SwiftUI // Temp for Preview

class NavigationViewController: UIViewController {
    private let mapView = MKMapView()
    private lazy var cameraManager = MapCameraManager(mapView: mapView)
    private var currentRoute: MKRoute?
    private lazy var routeManager = RouteManager(mapView: mapView)
    private var simulationTimer: Timer?
    private var simulationPoints: [CLLocationCoordinate2D] = []
    private var currentSimulationIndex = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupRouteManager()
        
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
        mapView.showsCompass = true
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.mapType = .mutedStandard
        mapView.userTrackingMode = .followWithHeading
    }
    
    private func setupRouteManager() {
        routeManager.onStepUpdated = { [weak self] step in
            print("Current instruction: \(step.instruction)")
            print("Distance to next turn: \(step.formattedDistance)")
            print("ETA: \(step.formattedETA)")
        }
        
        routeManager.onRouteDeviation = { [weak self] in
            print("Rerouting...")
        }
    }
    
    private func handleLocationUpdate(_ location: CLLocation) {
        cameraManager.updateCamera(for: location, heading: nil)
        routeManager.updateProgress(for: location)
    }
    
    private func handleHeadingUpdate(_ heading: CLHeading) {
        guard let currentLocation = LocationManager.shared.locationManager.location else {
            return
        }
        cameraManager.updateCamera(for: currentLocation, heading: heading.trueHeading)
    }
    
    func startDemoRoute() {
        let source = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)  // London
        let destination = CLLocationCoordinate2D(latitude: 51.5194, longitude: -0.1270)  // King's Cross
        
        let region = MKCoordinateRegion(
            center: source,
            latitudinalMeters: 2000,
            longitudinalMeters: 2000
        )
        mapView.setRegion(region, animated: false)
        
        routeManager.calculateRoute(source: source, destination: destination) { [weak self] route in
            guard let self = self else { return }
            
            // Extract route points for simulation
            let points = route.polyline.points()
            self.simulationPoints = (0..<route.polyline.pointCount).map {
                points[$0].coordinate
            }
            
            // Start simulation with faster updates
            self.simulationTimer = Timer.scheduledTimer(
                withTimeInterval: 0.5,  // Faster updates for smoother simulation
                repeats: true
            ) { [weak self] _ in
                self?.simulateNextLocation()
            }
        }
    }
    
    private func simulateNextLocation() {
        guard currentSimulationIndex < simulationPoints.count - 1 else {
            simulationTimer?.invalidate()
            return
        }
        
        let currentCoordinate = simulationPoints[currentSimulationIndex]
        let nextCoordinate = simulationPoints[currentSimulationIndex + 1]
        
        // Calculate heading between current and next point
        let heading = calculateHeading(from: currentCoordinate, to: nextCoordinate)
        
        let location = CLLocation(
            coordinate: currentCoordinate,
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            timestamp: Date()
        )
        
        // Instead of creating a CLHeading object, pass the heading value directly
        cameraManager.updateCamera(for: location, heading: heading)
        routeManager.updateProgress(for: location)
        
        currentSimulationIndex += 1
    }
    
    private func calculateHeading(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude.degreesToRadians
        let lon1 = from.longitude.degreesToRadians
        let lat2 = to.latitude.degreesToRadians
        let lon2 = to.longitude.degreesToRadians
        
        let dLon = lon2 - lon1
        
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        
        return radiansBearing.radiansToDegrees
    }
}

struct NavigationViewController_Previews: PreviewProvider {
    static var previews: some View {
        NavigationViewControllerRepresentable()
    }
}

struct NavigationViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NavigationViewController {
        let vc = NavigationViewController()
        // Start demo route after a short delay to ensure view is loaded
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            vc.startDemoRoute()
        }
        return vc
    }
    
    func updateUIViewController(_ uiViewController: NavigationViewController, context: Context) {}
}

private extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}
