import Foundation
import SwiftData

@Model
final class VocabularyItem {
    @Attribute(.unique) var word: String
    var definition: String
    var exampleSentence: String
    var pronunciation: String
    var partOfSpeech: String // e.g., "Noun", "Verb", "Adjective"
    var bandScore: Double? // e.g., 7.0, 8.5
    var category: String
    var notes: String
    
    // Advanced Fields
    var synonyms: String
    var antonyms: String
    var collocations: String

    
    // SRS Metadata
    var createdAt: Date
    var lastReviewedAt: Date?
    var nextReviewAt: Date?
    var masteryLevel: Int // 0 to 5
    var interval: Double // for SRS algorithm
    var easeFactor: Double // for SRS algorithm
    var repetitions: Int // consecutive successful reviews

    
    init(
        word: String,
        definition: String,
        exampleSentence: String = "",
        pronunciation: String = "",
        partOfSpeech: String = "",
        bandScore: Double? = nil,
        category: String = "General",
        notes: String = "",
        synonyms: String = "",
        antonyms: String = "",
        collocations: String = ""
    ) {
        self.word = word
        self.definition = definition
        self.exampleSentence = exampleSentence
        self.pronunciation = pronunciation
        self.partOfSpeech = partOfSpeech
        self.bandScore = bandScore
        self.category = category
        self.notes = notes
        self.synonyms = synonyms
        self.antonyms = antonyms
        self.collocations = collocations
        
        self.createdAt = Date()
        self.masteryLevel = 0
        self.interval = 1.0
        self.easeFactor = 2.5
        self.repetitions = 0
        self.nextReviewAt = Date(timeIntervalSinceNow: -60) // Ensure immediate availability

    }
}

