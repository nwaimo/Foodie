import SwiftUI
import WidgetKit

// MARK: - Widget Entry
struct FoodieEntry: TimelineEntry {
    let date: Date
    let waterAmount: Double
    let waterTarget: Double
    let calories: Int
    let calorieTarget: Int
    let healthStatus: HealthStatus
}

// MARK: - Timeline Provider
struct FoodieWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FoodieEntry {
        FoodieEntry(
            date: Date(),
            waterAmount: 1.5,
            waterTarget: 2.0,
            calories: 1500,
            calorieTarget: 2000,
            healthStatus: .normal
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (FoodieEntry) -> Void) {
        let entry = FoodieEntry(
            date: Date(),
            waterAmount: DataManager.shared.dailyWater,
            waterTarget: DataManager.shared.waterTarget,
            calories: DataManager.shared.dailyCalories,
            calorieTarget: DataManager.shared.calorieTarget,
            healthStatus: DataManager.shared.healthStatus
        )
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<FoodieEntry>) -> Void) {
        let currentDate = Date()
        let entry = FoodieEntry(
            date: currentDate,
            waterAmount: DataManager.shared.dailyWater,
            waterTarget: DataManager.shared.waterTarget,
            calories: DataManager.shared.dailyCalories,
            calorieTarget: DataManager.shared.calorieTarget,
            healthStatus: DataManager.shared.healthStatus
        )
        
        // Update every 30 minutes
        let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
}

// MARK: - Widget Views
struct FoodieWidgetSmallView: View {
    var entry: FoodieEntry
    
    var body: some View {
        ZStack {
            // Background with health status color
            Circle()
                .fill(healthStatusColor(entry.healthStatus))
                .opacity(0.2)
            
            VStack(spacing: 2) {
                // Water progress
                HStack(spacing: 2) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.blue)
                    
                    Text(String(format: "%.1f/%.1fL", entry.waterAmount, entry.waterTarget))
                        .font(.system(size: 10, weight: .medium))
                        .minimumScaleFactor(0.7)
                }
                
                // Progress bar for water
                ProgressView(value: min(entry.waterAmount / entry.waterTarget, 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .frame(height: 3)
                
                // Calories progress
                HStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    
                    Text("\(entry.calories)/\(entry.calorieTarget)")
                        .font(.system(size: 10, weight: .medium))
                        .minimumScaleFactor(0.7)
                }
                
                // Progress bar for calories
                ProgressView(value: min(Double(entry.calories) / Double(entry.calorieTarget), 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                    .frame(height: 3)
            }
            .padding(5)
        }
    }
    
    private func healthStatusColor(_ status: HealthStatus) -> Color {
        switch status {
        case .excellent:
            return .green
        case .needsWater:
            return .blue
        case .needsCalories:
            return .orange
        case .normal:
            return .gray
        }
    }
}

struct FoodieWidgetMediumView: View {
    var entry: FoodieEntry
    
    var body: some View {
        HStack {
            // Water section
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.blue)
                    Text("Water")
                        .font(.headline)
                }
                
                Text(String(format: "%.1f/%.1fL", entry.waterAmount, entry.waterTarget))
                    .font(.subheadline)
                
                ProgressView(value: min(entry.waterAmount / entry.waterTarget, 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                
                Text(String(format: "%.0f%%", min(entry.waterAmount / entry.waterTarget, 1.0) * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.trailing)
            
            Divider()
            
            // Calories section
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Calories")
                        .font(.headline)
                }
                
                Text("\(entry.calories)/\(entry.calorieTarget)")
                    .font(.subheadline)
                
                ProgressView(value: min(Double(entry.calories) / Double(entry.calorieTarget), 1.0))
                    .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                
                Text(String(format: "%.0f%%", min(Double(entry.calories) / Double(entry.calorieTarget), 1.0) * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(UIColor.systemBackground))
        )
    }
}

// MARK: - Widget Configuration
struct FoodieWidget: Widget {
    private let kind = "FoodieWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: FoodieWidgetProvider()
        ) { entry in
            if #available(watchOS 10.0, *) {
                FoodieWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                FoodieWidgetView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Foodie Tracker")
        .description("Track your daily water and calorie intake")
        .supportedFamilies([.accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}

struct FoodieWidgetView: View {
    @Environment(\.widgetFamily) var family
    var entry: FoodieEntry
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            FoodieWidgetSmallView(entry: entry)
        case .accessoryCorner:
            FoodieWidgetSmallView(entry: entry)
        case .accessoryInline:
            HStack {
                Image(systemName: "drop.fill")
                    .foregroundColor(.blue)
                Text(String(format: "%.1fL", entry.waterAmount))
                
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(entry.calories) cal")
            }
        default:
            FoodieWidgetMediumView(entry: entry)
        }
    }
}
