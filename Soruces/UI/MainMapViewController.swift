//
//  MainMapViewController.swift
//  MapNavigationDemo
//
//  Created by Arron Stothart on 15/11/2024.
//

import UIKit
import MapKit

public class MainMapViewController: UIViewController {
    private let mapView = MKMapView()
    private let bottomSheetVC = BottomSheetViewController()
    private var bottomSheetTopConstraint: NSLayoutConstraint?
    
    private enum SheetState {
        case collapsed
        case partial
        case expanded
        
        var heightFactor: CGFloat {
            switch self {
            case .collapsed: return 0.1
            case .partial: return 0.4
            case .expanded: return 0.9
            }
        }
    }
    
    private var currentState: SheetState = .collapsed {
        didSet {
            updateBottomSheetPosition(animated: true)
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupBottomSheet()
        
        let london = CLLocationCoordinate2D(latitude: 51.5074, longitude: -0.1278)
        let region = MKCoordinateRegion(
            center: london,
            latitudinalMeters: 5000,
            longitudinalMeters: 5000
        )
        mapView.setRegion(region, animated: false)

        let handlePanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        bottomSheetVC.handleView.addGestureRecognizer(handlePanGesture)
        bottomSheetVC.handleView.isUserInteractionEnabled = true  // Make sure this is enabled
        
        let sheetPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        bottomSheetVC.view.addGestureRecognizer(sheetPanGesture)
        bottomSheetVC.view.isUserInteractionEnabled = true  // Make sure this is enabled
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
    
    private func setupBottomSheet() {
        addChild(bottomSheetVC)
        view.addSubview(bottomSheetVC.view)
        bottomSheetVC.didMove(toParent: self)
        
        bottomSheetVC.view.translatesAutoresizingMaskIntoConstraints = false
        
        let topConstraint = bottomSheetVC.view.topAnchor.constraint(
            equalTo: view.bottomAnchor,
            constant: -view.bounds.height * SheetState.collapsed.heightFactor
        )
        bottomSheetTopConstraint = topConstraint
        
        NSLayoutConstraint.activate([
            topConstraint,
            bottomSheetVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomSheetVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomSheetVC.view.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        
        // Add pan gesture
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        bottomSheetVC.handleView.addGestureRecognizer(panGesture)
    }
    
    private func updateBottomSheetPosition(animated: Bool = true) {
        let height = view.bounds.height * currentState.heightFactor 
        bottomSheetTopConstraint?.constant = -height
        
        if animated {
            UIView.animate(
                withDuration: 0.3,
                delay: 0,
                options: .curveEaseInOut,
                animations: {
                    self.view.layoutIfNeeded()
                }
            )
        } else {
            view.layoutIfNeeded()
        }
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .changed:
            // Update position with pan
            let newConstant = -view.bounds.height * currentState.heightFactor - translation.y
            let maxHeight = -view.bounds.height * SheetState.expanded.heightFactor
            let minHeight = -view.bounds.height * SheetState.collapsed.heightFactor
            bottomSheetTopConstraint?.constant = min(max(newConstant, maxHeight), minHeight)
            
        case .ended:
            let currentHeight = abs(bottomSheetTopConstraint?.constant ?? 0)
            let expandedHeight = view.bounds.height * SheetState.expanded.heightFactor
            let partialHeight = view.bounds.height * SheetState.partial.heightFactor
            let collapsedHeight = view.bounds.height * SheetState.collapsed.heightFactor
            
            if velocity.y < -300 {
                if currentState == .collapsed {
                    currentState = .partial
                } else {
                    currentState = .expanded
                }
            } else if velocity.y > 300 {
                if currentState == .expanded {
                    currentState = .partial
                } else {
                    currentState = .collapsed
                }
            } else {
                let expandedThreshold = (expandedHeight + partialHeight) / 2
                let partialThreshold = (partialHeight + collapsedHeight) / 2
                
                if currentHeight > expandedThreshold {
                    currentState = .expanded
                } else if currentHeight > partialThreshold {
                    currentState = .partial
                } else {
                    currentState = .collapsed
                }
            }
            
        default:
            break
        }
    }
} 