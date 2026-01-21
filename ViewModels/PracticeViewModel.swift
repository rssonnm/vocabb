import Foundation
import SwiftData
import SwiftUI

@Observable
class PracticeViewModel {
    var modelContext: ModelContext?
    var wordsToReview: [VocabularyItem] = []
    var currentWordIndex: Int = 0
    var isShowingAnswer: Bool = false
    var isSessionComplete: Bool = false
    
    var currentWord: VocabularyItem? {
        guard currentWordIndex < wordsToReview.count else { return nil }
        return wordsToReview[currentWordIndex]
    }
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func fetchWords(category: String = "All") {
        guard let context = modelContext else { return }
        let bufferNow = Date(timeIntervalSinceNow: 1) // 1 second buffer for precision
        
        let descriptor = FetchDescriptor<VocabularyItem>(
            predicate: #Predicate<VocabularyItem> { item in
                (item.nextReviewAt == nil || item.nextReviewAt! <= bufferNow) &&
                (category == "All" || item.category == category)
            },
            sortBy: [SortDescriptor(\.nextReviewAt)]
        )
        
        do {
            wordsToReview = try context.fetch(descriptor)
            currentWordIndex = 0
            isSessionComplete = wordsToReview.isEmpty
        } catch {
            print("Failed to fetch words: \(error)")
        }
    }
    
    func submitAnswer(quality: Int) {
        guard let word = currentWord else { return }
        
        // Simple SM-2 like update
        updateSRS(word: word, quality: Int(quality))
        
        if currentWordIndex < wordsToReview.count - 1 {
            withAnimation {
                currentWordIndex += 1
                isShowingAnswer = false
            }
        } else {
            isSessionComplete = true
        }
        
        recordActivity(type: "Flashcard")
        try? modelContext?.save()
    }
    
    private func recordActivity(type: String) {
        guard let context = modelContext else { return }
        let today = Calendar.current.startOfDay(for: Date())
        
        let descriptor = FetchDescriptor<ActivityRecord>()
        
        do {
            let records = try context.fetch(descriptor)
            if let record = records.first(where: { Calendar.current.isDate($0.date, inSameDayAs: today) && $0.type == type }) {
                record.count += 1
            } else {
                let newRecord = ActivityRecord(date: today, type: type, count: 1)
                context.insert(newRecord)
            }
        } catch {
            print("Failed to record activity: \(error)")
        }
    }
    
    private func updateSRS(word: VocabularyItem, quality: Int) {
        // SM-2 algorithm implementation
        // quality: 0 (total blackout) to 5 (excellent response)
        
        word.lastReviewedAt = Date()
        let q = Double(quality)
        
        if quality < 3 {
            // Failure: Reset repetitions and interval
            word.repetitions = 0
            word.interval = 1
            word.masteryLevel = max(0, word.masteryLevel - 1)
        } else {
            // Success: Update repetitions and calculate new interval
            if word.repetitions == 0 {
                word.interval = 1
            } else if word.repetitions == 1 {
                word.interval = 6
            } else {
                word.interval = round(word.interval * word.easeFactor)
            }
            word.repetitions += 1
            word.masteryLevel = min(5, word.masteryLevel + 1)
        }
        
        // Update ease factor: EF = EF + (0.1 - (5-q) * (0.08 + (5-q) * 0.02))
        word.easeFactor = word.easeFactor + (0.1 - (5.0 - q) * (0.08 + (5.0 - q) * 0.02))
        if word.easeFactor < 1.3 { word.easeFactor = 1.3 }
        
        // Schedule next review
        let days = Int(word.interval)
        word.nextReviewAt = Calendar.current.date(byAdding: .day, value: days, to: Calendar.current.startOfDay(for: Date()))
    }

}
