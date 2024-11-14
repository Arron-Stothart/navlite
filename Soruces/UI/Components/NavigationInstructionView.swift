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
        label.font = .systemFont(ofSize: 96, weight: .bold)
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        return label
    }()
    
    private let streetNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white.withAlphaComponent(0.85) 
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    private let remainingInfoLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white.withAlphaComponent(0.85)
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textAlignment = .left
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
        containerView.addSubview(remainingInfoLabel)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        instructionImageView.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        streetNameLabel.translatesAutoresizingMaskIntoConstraints = false
        remainingInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        
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
            distanceLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: -10),
            distanceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            streetNameLabel.leadingAnchor.constraint(equalTo: instructionImageView.leadingAnchor),
            streetNameLabel.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: -4),
            streetNameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            
            remainingInfoLabel.leadingAnchor.constraint(equalTo: instructionImageView.leadingAnchor),
            remainingInfoLabel.topAnchor.constraint(equalTo: streetNameLabel.bottomAnchor, constant: 4),
            remainingInfoLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
    }
    
    func update(with step: RouteManager.NavigationStep) {
        // Smoothly animate the distance change
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveLinear, .beginFromCurrentState]) {
            self.updateDistance(step.distance)
            
            let components = step.instruction.components(separatedBy: " onto ")
            if components.count > 1 {
                self.streetNameLabel.text = components[1]
            } else {
                self.streetNameLabel.text = step.instruction
            }
            
            let remainingDistance = self.formatDistance(step.remainingDistance)
            let remainingTime = self.formatTime(step.remainingTime)
            self.remainingInfoLabel.text = "\(remainingTime) (\(remainingDistance) remaining)"
        }
    }
    
    private func updateDistance(_ distance: CLLocationDistance) {
        let text: String
        if distance < 1000 {
            text = "\(Int(distance))m"
        } else {
            text = String(format: "%.1f km", distance/1000)
        }
        
        // Only update if text actually changed to prevent label flicker
        if distanceLabel.text != text {
            distanceLabel.text = text
        }
    }
    
    private func iconFor(step: RouteManager.NavigationStep) -> UIImage? {
        // Implement your logic to determine the appropriate icon based on the step
        return nil
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            return String(format: "%.1f km", distance/1000)
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)min"
        } else {
            return "\(minutes)min"
        }
    }
}
