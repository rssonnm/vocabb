import Foundation
import SwiftData
import SwiftUI

@Observable
class QuizViewModel {
    var modelContext: ModelContext?
    var allItems: [VocabularyItem] = []
    var currentQuestion: QuizQuestion?
    var score: Int = 0
    var totalQuestions: Int = 0
    var isGameOver: Bool = false
    var incorrectAttempts: [IncorrectAttempt] = []
    
    struct QuizQuestion {
        let word: VocabularyItem
        let options: [String]
        let correctIndex: Int
    }
    
    struct IncorrectAttempt: Identifiable {
        let id = UUID()
        let word: String
        let definition: String
        let chosenAnswer: String
    }
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func startQuiz(category: String = "All") {
        guard let context = modelContext else { return }
        let descriptor = FetchDescriptor<VocabularyItem>(
            predicate: #Predicate<VocabularyItem> { item in
                category == "All" || item.category == category
            }
        )
        do {
            allItems = try context.fetch(descriptor)
            if allItems.count >= 4 {
                score = 0
                totalQuestions = 0
                incorrectAttempts = []
                isGameOver = false
                nextQuestion()
            }
        } catch {
            print("Failed to fetch words: \(error)")
        }
    }
    
    func nextQuestion() {
        guard allItems.count >= 4 else { return }
        
        let targetWord = allItems.randomElement()!
        var distractors = allItems.filter { $0.id != targetWord.id }
        distractors.shuffle()
        
        let options = ([targetWord.definition] + distractors.prefix(3).map { $0.definition }).shuffled()
        let correctIndex = options.firstIndex(of: targetWord.definition)!
        
        currentQuestion = QuizQuestion(word: targetWord, options: options, correctIndex: correctIndex)
        totalQuestions += 1
    }
    
    func submitAnswer(at index: Int) {
        guard let current = currentQuestion else { return }
        
        if index == current.correctIndex {
            score += 1
        } else {
            incorrectAttempts.append(IncorrectAttempt(
                word: current.word.word,
                definition: current.word.definition,
                chosenAnswer: current.options[index]
            ))
        }
        
        if totalQuestions < 10 {
            nextQuestion()
        } else {
            isGameOver = true
        }
        
        recordActivity(type: "Quiz")
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
            try? context.save()
        } catch {
            print("Failed to record activity: \(error)")
        }
    }
}
