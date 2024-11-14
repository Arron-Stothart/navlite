//
//  NavigationInstructionView.swift
//  MapNavigationDemo
//
//  Created by Arron Stothart on 14/11/2024.
//

import Foundation
import UIKit
import MapKit

class NavigationInstructionView: UIView {
    private let containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let instructionImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .white
        return imageView
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 48, weight: .bold)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    private let streetNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.numberOfLines = 1
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(containerView)
        containerView.addSubview(instructionImageView)
        containerView.addSubview(distanceLabel)
        containerView.addSubview(streetNameLabel)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        instructionImageView.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        streetNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            instructionImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            instructionImageView.centerYAnchor.constraint(equalTo: distanceLabel.centerYAnchor),
            instructionImageView.widthAnchor.constraint(equalToConstant: 48),
            instructionImageView.heightAnchor.constraint(equalToConstant: 48),
            
            distanceLabel.leadingAnchor.constraint(equalTo: instructionImageView.trailingAnchor, constant: 16),
            distanceLabel.topAnchor.constraint(equalTo: containerView.topAnchor),
            distanceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            streetNameLabel.leadingAnchor.constraint(equalTo: instructionImageView.leadingAnchor),
            streetNameLabel.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 4),
            streetNameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
    }
    
    func update(with step: RouteManager.NavigationStep) {
        instructionImageView.image = iconFor(step: step)?.withRenderingMode(.alwaysTemplate)
        updateDistance(step.distance)
        
        let components = step.instruction.components(separatedBy: " onto ")
        if components.count > 1 {
            streetNameLabel.text = components[1]
        } else {
            streetNameLabel.text = step.instruction
        }
    }
    
    func updateDistance(_ distance: CLLocationDistance) {
        if distance < 1000 {
            distanceLabel.text = "\(Int(distance))m"
        } else {
            distanceLabel.text = String(format: "%.1f km", distance/1000)
        }
    }
    
    private func iconFor(step: RouteManager.NavigationStep) -> UIImage? {
        // Implement your logic to determine the appropriate icon based on the step
        return nil
    }
}
