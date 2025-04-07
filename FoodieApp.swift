//  FoodieApp.swift
//  Foodie
//
//  Created on 2/28/2025.
//

import SwiftUI
import SwiftData
import WidgetKit

@main
struct FoodieApp: App {
    @StateObject private var dataManager = DataManager.shared
    
    init() {
        // Ensure WidgetKit is updated when data changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("RefreshWidgets"),
            object: nil,
            queue: .main
        ) { _ in
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataManager)
                .onChange(of: dataManager.dailyWater) { _, _ in
                    WidgetCenter.shared.reloadAllTimelines()
                }
                .onChange(of: dataManager.dailyCalories) { _, _ in
                    WidgetCenter.shared.reloadAllTimelines()
                }
        }
        .modelContainer(for: ConsumptionItem.self)
    }
}
