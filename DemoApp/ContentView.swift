//
//  ContentView.swift
//  DemoApp
//
//  Created by Arron Stothart on 14/11/2024.
//

import SwiftUI
import MapNavigationDemo

struct ContentView: View {
    var body: some View {
        MainMapViewControllerRepresentable()
            .ignoresSafeArea()
    }
}

struct MainMapViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> MainMapViewController {
        return MainMapViewController()
    }
    
    func updateUIViewController(_ uiViewController: MainMapViewController, context: Context) {}
}

#Preview {
    ContentView()
        .ignoresSafeArea()
}
