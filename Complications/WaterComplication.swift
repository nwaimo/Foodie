import SwiftUI
import ClockKit

// This file is kept for backward compatibility
// The widget functionality has been moved to the Widgets folder
// See Widgets/FoodieWidget.swift and Widgets/FoodieWidgetBundle.swift

class WaterComplication: NSObject, CLKComplicationDataSource {
    func getCurrentTimelineEntry(for complication: CLKComplication, withHandler handler: @escaping (CLKComplicationTimelineEntry?) -> Void) {
        // For backward compatibility, we'll still provide the water complication
        guard let template = createTemplate(for: complication) else {
            handler(nil)
            return
        }
        
        let entry = CLKComplicationTimelineEntry(
            date: Date(),
            complicationTemplate: template
        )
        handler(entry)
    }
    
    private func createTemplate(for complication: CLKComplication) -> CLKComplicationTemplate? {
        switch complication.family {
        case .circularSmall:
            let template = CLKComplicationTemplateCircularSmallRingText()
            template.textProvider = CLKSimpleTextProvider(text: String(format: "%.1fL", DataManager.shared.dailyWater))
            template.fillFraction = Float(DataManager.shared.dailyWater / DataManager.shared.waterTarget)
            return template
        default:
            return nil
        }
    }
}
