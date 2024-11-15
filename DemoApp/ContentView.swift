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
        NavigationViewControllerRepresentable()
            .preferredColorScheme(.dark)
            .ignoresSafeArea()
    }
}
