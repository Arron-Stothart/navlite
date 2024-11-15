import MapKit

class RouteSimulator {
    struct SimulationPoint {
        let coordinate: CLLocationCoordinate2D
        let heading: Double
        let distanceFromStart: Double
        let stepIndex: Int
    }
    
    private var simulationPoints: [SimulationPoint] = []
    private let route: MKRoute
    private var simulationSpeed: Double = 30 
    private let pointSpacing: Double = 5
    
    private var timer: CADisplayLink?
    private var startTime: CFTimeInterval = 0
    
    var onLocationUpdated: ((CLLocation, Double) -> Void)?
    
    init(route: MKRoute, speed: Double = 30) {
        self.route = route
        self.simulationSpeed = speed
        generateSimulationPoints()
    }
    
    private func generateSimulationPoints() {
        var points: [SimulationPoint] = []
        var totalDistance: Double = 0
        
        // Process each step in the route
        for (stepIndex, step) in route.steps.enumerated() {
            let stepPoints = Array(UnsafeBufferPointer(
                start: step.polyline.points(),
                count: step.polyline.pointCount
            ))
            
            // Interpolate between each pair of points in the step
            for i in 0..<(stepPoints.count - 1) {
                let startPoint = stepPoints[i]
                let endPoint = stepPoints[i + 1]
                
                let segmentDistance = startPoint.distance(to: endPoint)
                let numIntermediatePoints = max(1, Int(segmentDistance / pointSpacing))
                
                for j in 0...numIntermediatePoints {
                    let fraction = Double(j) / Double(numIntermediatePoints)
                    let interpolatedCoord = interpolate(
                        start: startPoint.coordinate,
                        end: endPoint.coordinate,
                        fraction: fraction
                    )
                    
                    let heading = calculateHeading(from: startPoint.coordinate, to: endPoint.coordinate)
                    
                    points.append(SimulationPoint(
                        coordinate: interpolatedCoord,
                        heading: heading,
                        distanceFromStart: totalDistance,
                        stepIndex: stepIndex
                    ))
                    
                    totalDistance += pointSpacing
                }
            }
        }
        
        simulationPoints = points
    }
    
    private func interpolate(
        start: CLLocationCoordinate2D,
        end: CLLocationCoordinate2D,
        fraction: Double
    ) -> CLLocationCoordinate2D {
        let lat = start.latitude + (end.latitude - start.latitude) * fraction
        let lon = start.longitude + (end.longitude - start.longitude) * fraction
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
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
    
    func start() {
        startTime = CACurrentMediaTime()
        timer = CADisplayLink(target: self, selector: #selector(update))
        timer?.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60)
        timer?.add(to: .main, forMode: .common)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    @objc private func update() {
        let elapsedTime = CACurrentMediaTime() - startTime
        let distanceTraveled = elapsedTime * simulationSpeed
        
        guard distanceTraveled < simulationPoints.last?.distanceFromStart ?? 0 else {
            stop()
            return
        }
        
        // Find the two points we're between
        guard let (i1, i2) = findPointIndices(forDistance: distanceTraveled) else { return }
        let p1 = simulationPoints[i1]
        let p2 = simulationPoints[i2]
        
        // Interpolate between them
        let segmentProgress = (distanceTraveled - p1.distanceFromStart) / (p2.distanceFromStart - p1.distanceFromStart)
        let currentCoord = interpolate(start: p1.coordinate, end: p2.coordinate, fraction: segmentProgress)
        
        // Create location with interpolated values
        let location = CLLocation(
            coordinate: currentCoord,
            altitude: 0,
            horizontalAccuracy: 10,
            verticalAccuracy: 10,
            timestamp: Date()
        )
        
        // Use heading from next few points for smoother turns
        let lookaheadPoints = 5
        let endIndex = min(i2 + lookaheadPoints, simulationPoints.count - 1)
        let futurePoint = simulationPoints[endIndex].coordinate
        let heading = calculateHeading(from: currentCoord, to: futurePoint)
        
        onLocationUpdated?(location, heading)
    }
    
    private func findPointIndices(forDistance distance: Double) -> (Int, Int)? {
        guard let firstIndex = simulationPoints.firstIndex(where: { $0.distanceFromStart > distance }) else {
            return nil
        }
        return (max(0, firstIndex - 1), firstIndex)
    }
}

private extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
} 
