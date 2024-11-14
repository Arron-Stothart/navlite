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
    
    private var currentInstruction: String?
    
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
        instructionImageView.widthAnchor.constraint(equalToConstant: 96), 
        instructionImageView.heightAnchor.constraint(equalToConstant: 96), 
        
            
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
        let components = step.instruction.components(separatedBy: " onto ")
        let newStreetName = components.count > 1 ? components[1] : step.instruction
        
        let shouldAnimate = currentInstruction != step.instruction
        let isFirstUpdate = currentInstruction == nil
        
        currentInstruction = step.instruction
        
        statsStackView.isHidden = false
        
        if shouldAnimate && !isFirstUpdate {
            let tempContainer = UIView()
            containerView.addSubview(tempContainer)
            tempContainer.translatesAutoresizingMaskIntoConstraints = false
            
            let tempImageView = UIImageView(image: self.iconFor(step: step))
            tempImageView.contentMode = .scaleAspectFit
            tempImageView.tintColor = .white
            
            let tempDistanceLabel = UILabel()
            tempDistanceLabel.text = formatDistance(step.distance)
            tempDistanceLabel.textColor = .white
            tempDistanceLabel.font = distanceLabel.font
            tempDistanceLabel.adjustsFontSizeToFitWidth = true
            tempDistanceLabel.minimumScaleFactor = 0.5
            
            let tempStreetLabel = UILabel()
            tempStreetLabel.text = newStreetName
            tempStreetLabel.textColor = streetNameLabel.textColor
            tempStreetLabel.font = streetNameLabel.font
            tempStreetLabel.textAlignment = .center
            tempStreetLabel.numberOfLines = 1
            
            tempContainer.addSubview(tempImageView)
            tempContainer.addSubview(tempDistanceLabel)
            tempContainer.addSubview(tempStreetLabel)
            
            [tempImageView, tempDistanceLabel, tempStreetLabel].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
            }
            
            NSLayoutConstraint.activate([
                tempContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
                tempContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                tempContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                tempContainer.bottomAnchor.constraint(equalTo: streetNameLabel.bottomAnchor),
                
                tempImageView.leadingAnchor.constraint(equalTo: instructionImageView.leadingAnchor),
                tempImageView.centerYAnchor.constraint(equalTo: instructionImageView.centerYAnchor),
                tempImageView.widthAnchor.constraint(equalTo: instructionImageView.widthAnchor),
                tempImageView.heightAnchor.constraint(equalTo: instructionImageView.heightAnchor),
                
                tempDistanceLabel.leadingAnchor.constraint(equalTo: distanceLabel.leadingAnchor),
                tempDistanceLabel.centerYAnchor.constraint(equalTo: distanceLabel.centerYAnchor),
                tempDistanceLabel.trailingAnchor.constraint(equalTo: distanceLabel.trailingAnchor),
                
                tempStreetLabel.leadingAnchor.constraint(equalTo: streetNameLabel.leadingAnchor),
                tempStreetLabel.topAnchor.constraint(equalTo: streetNameLabel.topAnchor),
                tempStreetLabel.trailingAnchor.constraint(equalTo: streetNameLabel.trailingAnchor)
            ])
            
            tempContainer.transform = CGAffineTransform(translationX: containerView.frame.width, y: 0)
            tempContainer.alpha = 0
            
            let currentViews = UIView()
            containerView.insertSubview(currentViews, at: 0)
            currentViews.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                currentViews.topAnchor.constraint(equalTo: containerView.topAnchor),
                currentViews.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                currentViews.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                currentViews.bottomAnchor.constraint(equalTo: streetNameLabel.bottomAnchor)
            ])
            
            [instructionImageView, distanceLabel, streetNameLabel].forEach {
                currentViews.addSubview($0)
            }
            
            UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut, animations: {
                currentViews.transform = CGAffineTransform(translationX: -self.containerView.frame.width, y: 0)
                currentViews.alpha = 0
                
                tempContainer.transform = .identity
                tempContainer.alpha = 1
            }) { _ in
                self.instructionImageView.image = self.iconFor(step: step)
                self.distanceLabel.text = self.formatDistance(step.distance)
                self.streetNameLabel.text = newStreetName
                
                [self.instructionImageView, self.distanceLabel, self.streetNameLabel].forEach {
                    self.containerView.addSubview($0)
                    $0.transform = .identity
                    $0.alpha = 1
                }
                
                currentViews.removeFromSuperview()
                tempContainer.removeFromSuperview()
            }
            
            UIView.transition(with: statsStackView, duration: 0.5, options: .transitionCrossDissolve) {
                self.updateStats(
                    remainingTime: step.remainingTime,
                    eta: step.eta,
                    remainingDistance: step.remainingDistance
                )
            }
        } else {
            self.instructionImageView.image = self.iconFor(step: step)
            self.distanceLabel.text = formatDistance(step.distance)
            self.streetNameLabel.text = newStreetName
            updateStats(
                remainingTime: step.remainingTime,
                eta: step.eta,
                remainingDistance: step.remainingDistance
            )
        }
    }
    
    private func updateStats(remainingTime: TimeInterval, eta: Date, remainingDistance: CLLocationDistance) {        
        let minutes = Int(remainingTime / 60)
        remainingTimeValue.superview?.isHidden = minutes <= 0
        if minutes > 0 {
            remainingTimeValue.text = "\(minutes)"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        arrivalTimeValue.text = formatter.string(from: eta)
        arrivalTimeValue.superview?.isHidden = false
        
        remainingDistanceValue.superview?.isHidden = remainingDistance <= 0
        if remainingDistance > 0 {
            if remainingDistance < 1000 {
                remainingDistanceValue.text = "\(Int(remainingDistance))"
                remainingDistanceUnit.text = "m"
            } else {
                remainingDistanceValue.text = String(format: "%.1f", remainingDistance/1000)
                remainingDistanceUnit.text = "km"
            }
        }
    }
    
    private func iconFor(step: RouteManager.NavigationStep) -> UIImage? {
        let instruction = step.instruction.lowercased()
        let imageName: String
        
        switch true {
        case instruction.contains("turn right"):
            imageName = "exit_right"
        case instruction.contains("turn left"):
            imageName = "exit_left"
        case instruction.contains("sharp right"):
            imageName = "sharp_right"
        case instruction.contains("sharp left"):
            imageName = "sharp_left"
        case instruction.contains("slight right"), instruction.contains("bear right"):
            imageName = "slight_right"
        case instruction.contains("slight left"), instruction.contains("bear left"):
            imageName = "slight_left"
        case instruction.contains("merge") && instruction.contains("right"):
            imageName = "merge_right"
        case instruction.contains("merge") && instruction.contains("left"):
            imageName = "merge_left"
        case instruction.contains("merge"):
            imageName = "merge"
        case instruction.contains("fork") && instruction.contains("right"):
            imageName = "fork_right"
        case instruction.contains("fork") && instruction.contains("left"):
            imageName = "fork_left"
        case instruction.contains("fork"):
            imageName = "fork"
        case instruction.contains("u-turn") && instruction.contains("right"):
            imageName = "uturn_right"
        case instruction.contains("u-turn"):
            imageName = "uturn_left"
        case instruction.contains("arrive"), instruction.contains("destination"):
            imageName = "flag"
        case instruction.contains("continue"), instruction.contains("head"):
            imageName = "continue_straight"
        default:
            imageName = "continue_straight"
        }
        
        let bundle = Bundle(for: type(of: self))
        return UIImage(named: imageName, in: bundle, compatibleWith: nil)
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
