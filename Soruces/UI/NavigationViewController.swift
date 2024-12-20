//
//  NavigationViewController.swift
//  MapNavigationDemo
//
//  Created by Arron Stothart on 12/11/2024.
//

import Foundation
import MapKit
import SwiftUI // Temp for Preview

public class NavigationViewController: UIViewController {
    private let mapView = MKMapView()
    private lazy var cameraManager = MapCameraManager(mapView: mapView)
    private var currentRoute: MKRoute?
    private lazy var routeManager = RouteManager(mapView: mapView)
    private var routeSimulator: RouteSimulator?
    private var topBlurView = VariableBlurView(style: .regular)
    private var bottomBlurView = VariableBlurView(style: .regular)
    private let navigationInstructionView = NavigationInstructionView()
    private let stopNavigationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Stop Navigation", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        
        let customRed = UIColor(red: 255/255, green: 16/255, blue: 29/255, alpha: 1.0)
        button.backgroundColor = customRed
        
        button.layer.cornerRadius = 26
        
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red: 255/255, green: 80/255, blue: 80/255, alpha: 0.3).cgColor
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        button.layer.masksToBounds = false
        
        return button
    }()

    private let plusButtom: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        let image = UIImage(systemName: "plus", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        
        button.layer.cornerRadius = 26
        
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        
        return button
    }()

    private let cameraButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let image = UIImage(systemName: "camera.fill", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        
        button.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        
        button.layer.cornerRadius = 26
        
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 4
        button.layer.shadowOpacity = 0.2
        
        return button
    }()

    private var simulatedUserLocation: SimulatedUserLocation?
    
    public override func viewDidLoad() {
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
        let mapContainer = UIView()
        view.addSubview(mapContainer)
        mapContainer.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mapContainer.topAnchor.constraint(equalTo: view.topAnchor, constant: -80), 
            mapContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant:  80)
        ])
        
        // Add mapView to the container
        mapContainer.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: mapContainer.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: mapContainer.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: mapContainer.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: mapContainer.bottomAnchor)
        ])
        
        // Apply transform to shift the map up
        mapContainer.transform = CGAffineTransform(translationX: 0, y: 80) 
        
        mapView.showsUserLocation = false
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.mapType = .mutedStandard
        mapView.userTrackingMode = .followWithHeading
        
        let london = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        simulatedUserLocation = SimulatedUserLocation(coordinate: london)
        if let simulatedUserLocation = simulatedUserLocation {
            mapView.addAnnotation(simulatedUserLocation)
        }
        
        setupBlurViews()
        
        // Add navigation instruction view to top blur view
        view.addSubview(navigationInstructionView)
        navigationInstructionView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            navigationInstructionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            navigationInstructionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationInstructionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationInstructionView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func setupBlurViews() {
        view.addSubview(topBlurView)
        view.addSubview(bottomBlurView)

        view.backgroundColor = .clear
        
        view.addSubview(navigationInstructionView)
        view.addSubview(stopNavigationButton)
        view.addSubview(plusButtom)
        view.addSubview(cameraButton)
        plusButtom.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        
        topBlurView.translatesAutoresizingMaskIntoConstraints = false
        bottomBlurView.translatesAutoresizingMaskIntoConstraints = false
        stopNavigationButton.translatesAutoresizingMaskIntoConstraints = false
        plusButtom.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            topBlurView.topAnchor.constraint(equalTo: view.topAnchor),
            topBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBlurView.heightAnchor.constraint(equalToConstant: 360),
            
            bottomBlurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBlurView.heightAnchor.constraint(equalToConstant: 150),
            
            navigationInstructionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            navigationInstructionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationInstructionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationInstructionView.heightAnchor.constraint(equalToConstant: 100),
            
            stopNavigationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopNavigationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stopNavigationButton.widthAnchor.constraint(equalToConstant: 160),
            stopNavigationButton.heightAnchor.constraint(equalToConstant: 52),
            
            plusButtom.centerYAnchor.constraint(equalTo: stopNavigationButton.centerYAnchor),
            plusButtom.trailingAnchor.constraint(equalTo: stopNavigationButton.leadingAnchor, constant: -16),
            plusButtom.widthAnchor.constraint(equalToConstant: 52),
            plusButtom.heightAnchor.constraint(equalToConstant: 52),
            
            cameraButton.centerYAnchor.constraint(equalTo: stopNavigationButton.centerYAnchor),
            cameraButton.leadingAnchor.constraint(equalTo: stopNavigationButton.trailingAnchor, constant: 16),
            cameraButton.widthAnchor.constraint(equalToConstant: 52),
            cameraButton.heightAnchor.constraint(equalToConstant: 52)
        ])
        
        topBlurView.updateMasks(isTop: true)
        bottomBlurView.updateMasks(isTop: false)
        
        stopNavigationButton.addTarget(self, action: #selector(stopNavigationTapped), for: .touchUpInside)
        plusButtom.addTarget(self, action: #selector(plusButtomTapped), for: .touchUpInside)
        cameraButton.addTarget(self, action: #selector(cameraButtonTapped), for: .touchUpInside)
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let topMask = topBlurView.layer.mask,
           let bottomMask = bottomBlurView.layer.mask {
            topMask.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 200)
            bottomMask.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: 100)
        }
    }
    
    private func setupRouteManager() {
        routeManager.onStepUpdated = { [weak self] step in
            self?.navigationInstructionView.update(with: step)
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
    
    public func startDemoRoute() {
        // Old Port of Montreal
        let source = CLLocationCoordinate2D(latitude: 45.5017, longitude: -73.5516)
        // Mount Royal Lookout
        let destination = CLLocationCoordinate2D(latitude: 45.5048, longitude: -73.5874)
        
        let region = MKCoordinateRegion(
            center: source,
            latitudinalMeters: 1000,
            longitudinalMeters: 1000
        )
        mapView.setRegion(region, animated: false)
        
        routeManager.calculateRoute(source: source, destination: destination) { [weak self] route in
            guard let self = self else { return }
            
            self.routeSimulator = RouteSimulator(route: route, speed: 30)
            
            self.routeSimulator?.onLocationUpdated = { [weak self] location, heading in
                guard let self = self else { return }
                
                self.simulatedUserLocation?.coordinate = location.coordinate
                self.simulatedUserLocation?.location = location
                
                let simulatedHeading = SimulatedCLHeading(trueHeading: heading)
                self.simulatedUserLocation?.heading = simulatedHeading
                
                self.cameraManager.updateCamera(
                    for: location,
                    heading: heading,
                    animated: true
                )
                
                self.routeManager.updateProgress(for: location)
            }
            self.routeSimulator?.start()
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        let blurStyle: UIBlurEffect.Style = traitCollection.userInterfaceStyle == .dark ? .dark : .regular
        topBlurView.removeFromSuperview()
        bottomBlurView.removeFromSuperview()
        let newTopBlur = VariableBlurView(style: blurStyle)
        let newBottomBlur = VariableBlurView(style: blurStyle)
        topBlurView = newTopBlur
        bottomBlurView = newBottomBlur
        setupBlurViews()
    }
    
    @objc private func stopNavigationTapped() {
        routeSimulator?.stop()
        routeSimulator = nil
        
        if let overlay = routeManager.routeOverlay {
            mapView.removeOverlay(overlay)
        }
        
        dismiss(animated: true)
    }

    @objc private func plusButtomTapped() {
        // TODO: Implement functionality
    }

    @objc private func cameraButtonTapped() {
        // TODO: Implement functionality
    }
}

public class VariableBlurView: UIView {
    public let blurLayers: [UIVisualEffectView]
    
    public init(style: UIBlurEffect.Style, blurSteps: Int = 15) {
        blurLayers = (0..<blurSteps).map { _ in
            let effect = UIBlurEffect(style: style)
            let view = UIVisualEffectView(effect: effect)
            return view
        }
        
        super.init(frame: .zero)
        backgroundColor = .clear
        isOpaque = false
        
        blurLayers.forEach { blurView in
            addSubview(blurView)
            blurView.backgroundColor = .clear
            blurView.isOpaque = false
            blurView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                blurView.topAnchor.constraint(equalTo: topAnchor),
                blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
                blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
                blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func updateMasks(isTop: Bool) {
        let steps = blurLayers.count
        blurLayers.enumerated().forEach { index, blurView in
            let maskLayer = CAGradientLayer()
            
            let startPoint = CGFloat(index) / CGFloat(steps - 1)
            let endPoint = CGFloat(index + 1) / CGFloat(steps - 1)
            
            if isTop {
                maskLayer.colors = [UIColor.white.cgColor, UIColor.clear.cgColor]
                maskLayer.locations = [0.0, 1.0]
                maskLayer.startPoint = CGPoint(x: 0.5, y: startPoint)
                maskLayer.endPoint = CGPoint(x: 0.5, y: endPoint)
                
                let intensity = (1.0 - startPoint) * 0.5
                blurView.alpha = intensity
            } else {
                maskLayer.colors = [UIColor.clear.cgColor, UIColor.white.cgColor]
                maskLayer.locations = [0.0, 1.0]
                maskLayer.startPoint = CGPoint(x: 0.5, y: 1.0 - endPoint)
                maskLayer.endPoint = CGPoint(x: 0.5, y: 1.0 - startPoint)
                
                let intensity = startPoint
                blurView.alpha = (1.0 - intensity) * 0.5
            }
            
            maskLayer.frame = bounds
            blurView.layer.mask = maskLayer
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        blurLayers.forEach { $0.layer.mask?.frame = bounds }
    }
}

struct NavigationViewController_Previews: PreviewProvider {
    static var previews: some View {
        NavigationViewControllerRepresentable()
            .preferredColorScheme(.dark)
            .ignoresSafeArea()
    }
}

public struct NavigationViewControllerRepresentable: UIViewControllerRepresentable {
    public init() {} 
    public func makeUIViewController(context: Context) -> NavigationViewController {
        let vc = NavigationViewController()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            vc.startDemoRoute()
        }
        return vc
    }
    
    public func updateUIViewController(_ uiViewController: NavigationViewController, context: Context) {}
}

private extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}

public class SimulatedCLHeading: CLHeading {
    private let simulatedTrueHeading: CLLocationDirection
    
    override public var trueHeading: CLLocationDirection {
        return simulatedTrueHeading
    }
    
    override public var magneticHeading: CLLocationDirection {
        return simulatedTrueHeading
    }
    
    public init(trueHeading: CLLocationDirection) {
        self.simulatedTrueHeading = trueHeading
        super.init()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
