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
    
    private let statsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 18
        stack.distribution = .fillEqually 
        stack.alignment = .center
        stack.isHidden = true
        return stack
    }()
    
    private func createStatColumn(value: UILabel, unit: UILabel) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.addArrangedSubview(value)
        stack.addArrangedSubview(unit)
        stack.isHidden = true
        return stack
    }
    
    private let remainingTimeValue: UILabel = {
        let label = UILabel()
        label.textColor = .white.withAlphaComponent(0.85)
        label.font = .systemFont(ofSize: 20, weight: .medium)
        return label
    }()
    
    private let remainingTimeUnit: UILabel = {
        let label = UILabel()
        label.textColor = .white.withAlphaComponent(0.7)
        label.font = .systemFont(ofSize: 20, weight: .regular)
        label.text = "min"
        return label
    }()
    
    private let arrivalTimeValue: UILabel = {
        let label = UILabel()
        label.textColor = .white.withAlphaComponent(0.85)
        label.font = .systemFont(ofSize: 20, weight: .medium)
        return label
    }()
    
    private let arrivalTimeUnit: UILabel = {
        let label = UILabel()
        label.textColor = .white.withAlphaComponent(0.7)
        label.font = .systemFont(ofSize: 20, weight: .regular) 
        label.text = "Arriving"
        return label
    }()
    
    private let remainingDistanceValue: UILabel = {
        let label = UILabel()
        label.textColor = .white.withAlphaComponent(0.85)
        label.font = .systemFont(ofSize: 20, weight: .medium)
        return label
    }()
    
    private let remainingDistanceUnit: UILabel = {
        let label = UILabel()
        label.textColor = .white.withAlphaComponent(0.7)
        label.font = .systemFont(ofSize: 20, weight: .regular) 
        label.text = "km"
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
        containerView.addSubview(statsStackView)
        
        let timeColumn = createStatColumn(value: remainingTimeValue, unit: remainingTimeUnit)
        let arrivalColumn = createStatColumn(value: arrivalTimeValue, unit: arrivalTimeUnit)
        let distanceColumn = createStatColumn(value: remainingDistanceValue, unit: remainingDistanceUnit)
        
        statsStackView.addArrangedSubview(timeColumn)
        statsStackView.addArrangedSubview(arrivalColumn)
        statsStackView.addArrangedSubview(distanceColumn)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        instructionImageView.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        streetNameLabel.translatesAutoresizingMaskIntoConstraints = false
        statsStackView.translatesAutoresizingMaskIntoConstraints = false
        
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
            
            statsStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 32),
            statsStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -32),
            statsStackView.topAnchor.constraint(equalTo: streetNameLabel.bottomAnchor, constant: 12)
        ])
    }
    
    func update(with step: RouteManager.NavigationStep) {
        UIView.animate(withDuration: 0.1, delay: 0, options: [.curveLinear, .beginFromCurrentState]) {
            self.updateDistance(step.distance)
            
            let components = step.instruction.components(separatedBy: " onto ")
            if components.count > 1 {
                self.streetNameLabel.text = components[1]
            } else {
                self.streetNameLabel.text = step.instruction
            }
            
            self.updateStats(
                remainingTime: step.remainingTime,
                eta: step.eta,
                remainingDistance: step.remainingDistance
            )
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
    
    private func updateStats(remainingTime: TimeInterval, eta: Date, remainingDistance: CLLocationDistance) {
        statsStackView.isHidden = false
        
        let minutes = Int(remainingTime / 60)
        if minutes > 0 {
            remainingTimeValue.text = "\(minutes)"
            remainingTimeValue.superview?.isHidden = false
        } else {
            remainingTimeValue.superview?.isHidden = true
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        arrivalTimeValue.text = formatter.string(from: eta)
        arrivalTimeValue.superview?.isHidden = false
        
        if remainingDistance > 0 {
            if remainingDistance < 1000 {
                remainingDistanceValue.text = "\(Int(remainingDistance))"
                remainingDistanceUnit.text = "m"
            } else {
                remainingDistanceValue.text = String(format: "%.1f", remainingDistance/1000)
                remainingDistanceUnit.text = "km"
            }
            remainingDistanceValue.superview?.isHidden = false
        } else {
            remainingDistanceValue.superview?.isHidden = true
        }
    }
    
    private func iconFor(step: RouteManager.NavigationStep) -> UIImage? {
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
