//  FoodieApp.swift
//  Foodie
//
//  Created on 2/28/2025.
//

import SwiftUI

@main
struct FoodieApp: App {
    @StateObject private var dataManager = DataManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
        }
    }
}
