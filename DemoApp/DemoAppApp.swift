//
//  DemoAppApp.swift
//  DemoApp
//
//  Created by Arron Stothart on 14/11/2024.
//

import SwiftUI

@main
struct DemoAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
