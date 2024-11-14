import MapKit

class SimulatedUserLocation: MKUserLocation {
    private var simulatedCoordinate: CLLocationCoordinate2D
    private var simulatedLocation: CLLocation?
    private var simulatedHeading: CLHeading?
    
    override dynamic var coordinate: CLLocationCoordinate2D {
        get { simulatedCoordinate }
        set { simulatedCoordinate = newValue }
    }
    
    override var location: CLLocation? {
        get { simulatedLocation }
        set { simulatedLocation = newValue }
    }
    
    override var heading: CLHeading? {
        get { simulatedHeading }
        set { simulatedHeading = newValue }
    }
    
    init(coordinate: CLLocationCoordinate2D) {
        self.simulatedCoordinate = coordinate
        super.init()
    }
} 