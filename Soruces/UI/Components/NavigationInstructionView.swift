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
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private let instructionLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.numberOfLines = 0
        return label
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 16, weight: .regular)
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
        containerView.addSubview(instructionLabel)
        containerView.addSubview(distanceLabel)
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            instructionLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            instructionLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            distanceLabel.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 8),
            distanceLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            distanceLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            distanceLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    func update(with step: RouteManager.NavigationStep) {
        instructionLabel.text = step.instruction
        distanceLabel.text = "In \(step.formattedDistance) • ETA \(step.formattedETA)"
    }
}
