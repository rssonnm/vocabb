import Foundation
import SwiftData

class CSVImporter {
    static let shared = CSVImporter()
    private init() {}
    
    func importCSV(from url: URL, modelContext: ModelContext) throws -> Int {
        guard url.startAccessingSecurityScopedResource() else {
            throw CSVImportError.permissionDenied
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        let content = try String(contentsOf: url, encoding: .utf8)
        let rows = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        let header = rows[0].lowercased().components(separatedBy: ",")
        
        // Map headers to indices
        let wordIndex = header.firstIndex(of: "word")
        let defIndex = header.firstIndex(of: "definition")
        
        guard wordIndex != nil, defIndex != nil else {
            throw CSVImportError.missingHeaders
        }
        
        let exIndex = header.firstIndex(of: "examplesentence")
        let posIndex = header.firstIndex(of: "partofspeech")
        let bandIndex = header.firstIndex(of: "bandscore")
        let catIndex = header.firstIndex(of: "category")
        let synIndex = header.firstIndex(of: "synonyms")
        let antIndex = header.firstIndex(of: "antonyms")
        let colIndex = header.firstIndex(of: "collocations")
        
        var importedCount = 0
        
        for i in 1..<rows.count {
            let columns = parseCSVRow(rows[i])
            guard let wordIdx = wordIndex, wordIdx < columns.count, !columns[wordIdx].isEmpty else { continue }
            guard let defIdx = defIndex, defIdx < columns.count, !columns[defIdx].isEmpty else { continue }
            
            let word = columns[wordIdx].trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Basic duplicate detection
            let descriptor = FetchDescriptor<VocabularyItem>(predicate: #Predicate<VocabularyItem> { $0.word == word })
            let existing = try? modelContext.fetch(descriptor)
            if existing?.first != nil { continue }
            
            let newItem = VocabularyItem(
                word: word,
                definition: columns[defIdx],
                exampleSentence: exIndex != nil && exIndex! < columns.count ? columns[exIndex!] : "",
                partOfSpeech: posIndex != nil && posIndex! < columns.count ? columns[posIndex!] : "Noun",
                bandScore: bandIndex != nil && bandIndex! < columns.count ? Double(columns[bandIndex!]) : nil,
                category: catIndex != nil && catIndex! < columns.count ? columns[catIndex!] : "General",
                synonyms: synIndex != nil && synIndex! < columns.count ? columns[synIndex!] : "",
                antonyms: antIndex != nil && antIndex! < columns.count ? columns[antIndex!] : "",
                collocations: colIndex != nil && colIndex! < columns.count ? columns[colIndex!] : ""
            )
            
            modelContext.insert(newItem)
            importedCount += 1
        }
        
        try modelContext.save()
        return importedCount
    }
    
    // Simple CSV parser to handle quotes if any (basic implementation)
    private func parseCSVRow(_ row: String) -> [String] {
        var result = [String]()
        var current = ""
        var insideQuotes = false
        
        for char in row {
            if char == "\"" {
                insideQuotes.toggle()
            } else if char == "," && !insideQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
    }
}

enum CSVImportError: LocalizedError {
    case permissionDenied
    case missingHeaders
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission denied. Please ensure the app has access to the selected file."
        case .missingHeaders:
            return "Invalid CSV format. The file must include 'word' and 'definition' columns."
        }
    }
}
