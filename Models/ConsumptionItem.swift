//  ConsumptionItem.swift
//  Foodie
//
//  Created on 2/28/2025.
//

import Foundation

enum MealCategory: String, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
    case drink
}

struct ConsumptionItem: Identifiable, Codable {
    let id: UUID
    let category: MealCategory
    let calories: Int
    let timestamp: Date
    let waterAmount: Double? // in liters
}

// Extension for icon representation
extension MealCategory: Codable {
    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snack: return "leaf.fill"
        case .drink: return "drop.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .indigo
        case .snack: return .green
        case .drink: return .blue
        }
    }
}

import SwiftUI
