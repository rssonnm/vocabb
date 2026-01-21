import Foundation
import SwiftData

@Model
final class ActivityRecord {
    var date: Date
    var type: String // "Quiz" or "Flashcard"
    var count: Int
    
    init(date: Date = Date(), type: String, count: Int = 1) {
        // Start of day to group correctly
        let calendar = Calendar.current
        self.date = calendar.startOfDay(for: date)
        self.type = type
        self.count = count
    }
}
