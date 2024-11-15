//
//  BottomSheetViewController.swift
//  MapNavigationDemo
//
//  Created by Arron Stothart on 15/11/2024.
//

import UIKit

public class BottomSheetViewController: UIViewController {
    // MARK: - UI Components
    public let handleView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray3
        view.layer.cornerRadius = 2.5
        return view
    }()
    
    private let searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.placeholder = "Search maps"
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = .secondarySystemBackground
        searchBar.layer.cornerRadius = 10
        searchBar.clipsToBounds = true
        return searchBar
    }()
    
    private let profileButton: UIButton = {
        let button = UIButton()
        button.setTitle("AA", for: .normal)
        button.backgroundColor = .systemGray3
        button.layer.cornerRadius = 18
        button.titleLabel?.font = .systemFont(ofSize: 14)
        return button
    }()
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        return scrollView
    }()
    
    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 20
        stackView.alignment = .fill
        return stackView
    }()
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupContent()
    }
    
    // MARK: - Setup
    private func setupViews() {
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 10
        
        let topStack = createTopStack()
        
        [handleView, topStack, scrollView].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        scrollView.addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Handle View
            handleView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            handleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handleView.widthAnchor.constraint(equalToConstant: 36),
            handleView.heightAnchor.constraint(equalToConstant: 5),
            
            // Top Stack
            topStack.topAnchor.constraint(equalTo: handleView.bottomAnchor, constant: 20),
            topStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            topStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Profile Button
            profileButton.widthAnchor.constraint(equalToConstant: 36),
            profileButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Scroll View
            scrollView.topAnchor.constraint(equalTo: topStack.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Content Stack
            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
    }
    
    private func createTopStack() -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.addArrangedSubview(searchBar)
        stack.addArrangedSubview(profileButton)
        return stack
    }
    
    private func setupContent() {
        let sections: [SheetSection] = [
            .siriSuggestions(title: "Siri Suggestions", items: [
                .init(icon: "car.fill", title: "Parked Car", subtitle: "290 m away, near ulica Krasnoarmejska")
            ]),
            .favorites(title: "Favorites", items: [
                .init(icon: "house.fill", title: "Home", showAddLabel: true),
                .init(icon: "briefcase.fill", title: "Work", showAddLabel: true),
                .init(icon: "plus", title: "Add", showAddLabel: false)
            ])
        ]
        
        sections.forEach { section in
            let sectionView = createSectionView(for: section)
            contentStackView.addArrangedSubview(sectionView)
        }
    }
}

// MARK: - Section Models and Factories
private extension BottomSheetViewController {
    enum SheetSection {
        case siriSuggestions(title: String, items: [SectionItem])
        case favorites(title: String, items: [SectionItem])
        
        var title: String {
            switch self {
            case .siriSuggestions(let title, _), .favorites(let title, _):
                return title
            }
        }
    }
    
    struct SectionItem {
        let icon: String
        let title: String
        let subtitle: String?
        let showAddLabel: Bool
        
        init(icon: String, title: String, subtitle: String? = nil, showAddLabel: Bool = false) {
            self.icon = icon
            self.title = title
            self.subtitle = subtitle
            self.showAddLabel = showAddLabel
        }
    }
    
    func createSectionView(for section: SheetSection) -> UIView {
        let sectionView = UIView()
        let titleLabel = createSectionTitle(text: section.title)
        
        sectionView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let contentView = createSectionContent(for: section)
        sectionView.addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: sectionView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor),
            
            contentView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            contentView.leadingAnchor.constraint(equalTo: sectionView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: sectionView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: sectionView.bottomAnchor)
        ])
        
        return sectionView
    }
    
    func createSectionTitle(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        label.textColor = .secondaryLabel
        return label
    }
    
    func createSectionContent(for section: SheetSection) -> UIView {
        let container = UIView()
        container.backgroundColor = .secondarySystemBackground
        container.layer.cornerRadius = 10
        
        switch section {
        case .siriSuggestions(_, let items):
            setupSiriSuggestionsContent(in: container, items: items)
        case .favorites(_, let items):
            setupFavoritesContent(in: container, items: items)
        }
        
        return container
    }
    
    func setupSiriSuggestionsContent(in container: UIView, items: [SectionItem]) {
        items.forEach { item in
            let itemView = createSuggestionItemView(item: item)
            container.addSubview(itemView)
            itemView.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                itemView.topAnchor.constraint(equalTo: container.topAnchor),
                itemView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                itemView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                itemView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                itemView.heightAnchor.constraint(equalToConstant: 73)
            ])
        }
    }
    
    func setupFavoritesContent(in container: UIView, items: [SectionItem]) {
        let horizontalStack = UIStackView()
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = 24
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(horizontalStack)
        
        NSLayoutConstraint.activate([
            horizontalStack.topAnchor.constraint(equalTo: container.topAnchor, constant: 16),
            horizontalStack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            horizontalStack.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -16),
            // Remove trailing constraint to allow natural flow
        ])
        
        items.forEach { item in
            let itemView = createFavoriteItemView(item: item)
            horizontalStack.addArrangedSubview(itemView)
        }
    }
    
    func createSuggestionItemView(item: SectionItem) -> UIView {
        let container = UIView()
        
        let iconContainer = UIView()
        iconContainer.backgroundColor = .systemBlue
        iconContainer.layer.cornerRadius = 15
        
        let iconLabel = UILabel()
        iconLabel.text = item.icon
        iconLabel.font = .systemFont(ofSize: 14)
        iconLabel.textColor = .white
        
        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 3
        
        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = item.subtitle
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = .secondaryLabel
        
        [iconContainer, iconLabel, titleStack].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        
        container.addSubview(iconContainer)
        iconContainer.addSubview(iconLabel)
        container.addSubview(titleStack)
        titleStack.addArrangedSubview(titleLabel)
        if let _ = item.subtitle {
            titleStack.addArrangedSubview(subtitleLabel)
        }
        
        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            iconContainer.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 30),
            iconContainer.heightAnchor.constraint(equalToConstant: 30),
            
            iconLabel.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconLabel.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            
            titleStack.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 12),
            titleStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16)
        ])
        
        return container
    }
    
    func createFavoriteItemView(item: SectionItem) -> UIView {
        let container = UIView()

        let verticalStack = UIStackView()
        verticalStack.axis = .vertical
        verticalStack.spacing = 6
        verticalStack.alignment = .center
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(verticalStack)
        
        let iconContainer = UIView()
        iconContainer.backgroundColor = .tertiarySystemBackground
        iconContainer.layer.cornerRadius = 30
        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        
        let iconImage = UIImageView()
        iconImage.contentMode = .center
        if item.title == "Add" {
            iconImage.image = UIImage(systemName: "plus")?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 24, weight: .medium))
        } else {
            iconImage.image = UIImage(systemName: item.icon)?.withConfiguration(UIImage.SymbolConfiguration(pointSize: 24, weight: .medium))
        }
        iconImage.tintColor = .systemBlue
        iconImage.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = item.showAddLabel ? "Add" : nil
        subtitleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        
        verticalStack.addArrangedSubview(iconContainer)
        iconContainer.addSubview(iconImage)
        verticalStack.addArrangedSubview(titleLabel)
        if item.showAddLabel {
            verticalStack.addArrangedSubview(subtitleLabel)
        }
        
        NSLayoutConstraint.activate([
            verticalStack.topAnchor.constraint(equalTo: container.topAnchor),
            verticalStack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            verticalStack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            verticalStack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            
            container.widthAnchor.constraint(equalToConstant: 60),
            
            iconContainer.widthAnchor.constraint(equalToConstant: 60),
            iconContainer.heightAnchor.constraint(equalToConstant: 60),
            
            iconImage.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconImage.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconImage.widthAnchor.constraint(equalToConstant: 36),
            iconImage.heightAnchor.constraint(equalToConstant: 36)
        ])
        
        return container 
    }
}
