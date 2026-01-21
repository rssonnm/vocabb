import SwiftUI
import SwiftData

struct VocabDetailView: View {
    let item: VocabularyItem
    
    var body: some View {
        ZStack {
            DashboardBackground()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Editorial Header
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(item.word)
                                    .font(.system(size: 64, weight: .black, design: .rounded))
                                    .foregroundStyle(Theme.primaryAccent)
                                
                                HStack(spacing: 12) {
                                    if !item.pronunciation.isEmpty {
                                        Text("/\(item.pronunciation)/")
                                            .font(.title3.monospaced())
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Button(action: { AudioService.shared.speak(item.word) }) {
                                        Image(systemName: "speaker.wave.3.fill")
                                            .font(.title3)
                                            .padding(10)
                                            .background(Theme.primaryAccent.opacity(0.1))
                                            .foregroundStyle(Theme.primaryAccent)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            
                            Spacer()
                            
                            if let score = item.bandScore {
                                BandScoreBadge(score: score)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            BadgeView(text: item.partOfSpeech.uppercased(), color: Theme.primaryTeal)
                            BadgeView(text: item.category.uppercased(), color: Theme.lightGreen)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 40)
                    
                    VStack(spacing: 24) {
                        // Definition
                        EditorialCard(title: "Definition") {
                            Text(item.definition)
                                .font(.system(size: 20, weight: .medium, design: .serif))
                                .lineSpacing(6)
                                .foregroundStyle(.primary.opacity(0.8))
                        }
                        
                        // Example
                        if !item.exampleSentence.isEmpty {
                            EditorialCard(title: "Usage Context") {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("\"\(item.exampleSentence)\"")
                                        .italic()
                                        .font(.system(size: 18, weight: .regular, design: .serif))
                                        .lineSpacing(6)
                                        .foregroundStyle(.secondary)
                                    
                                    Divider().opacity(0.1)
                                    
                                    Text("EXAMPLE SENTENCE")
                                        .font(.system(size: 10, weight: .black))
                                        .foregroundStyle(.secondary.opacity(0.4))
                                }
                            }
                        }
                        
                        // Synonyms & Antonyms
                        HStack(spacing: 24) {
                            if !item.synonyms.isEmpty {
                                EditorialCard(title: "Synonyms") {
                                    Text(item.synonyms)
                                        .font(.headline)
                                        .foregroundStyle(Theme.primaryTeal)
                                }
                            }
                            
                            if !item.antonyms.isEmpty {
                                EditorialCard(title: "Antonyms") {
                                    Text(item.antonyms)
                                        .font(.headline)
                                        .foregroundStyle(Theme.coral)
                                }
                            }
                        }
                        
                            EditorialCard(title: "Common Collocations") {
                                Text(item.collocations)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Theme.primaryAccent)
                            }
                        
                        // Mastery & SRS
                        EditorialCard(title: "Learning Progress") {
                            masteryContent
                        }
                        
                        if !item.notes.isEmpty {
                            EditorialCard(title: "Notes") {
                                Text(item.notes)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 60)
                }
            }
        }
        .navigationTitle("")
    }
    
    private var masteryContent: some View {
        HStack(spacing: 40) {
            CircularProgressView(progress: Double(item.masteryLevel) / 5.0, color: masteryColor)
                .frame(width: 80, height: 80)
                .overlay {
                    VStack(spacing: 0) {
                        Text("\(Int((Double(item.masteryLevel) / 5.0) * 100))%")
                            .font(.system(size: 16, weight: .black))
                        Text("LEVEL")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                }
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(masteryDescription)
                        .font(.headline)
                        .foregroundStyle(masteryColor)
                    Text("Phase")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Divider().opacity(0.1)
                
                HStack(spacing: 24) {
                    VocabInfoLabel(title: "Last Review", value: item.lastReviewedAt?.formatted(date: .abbreviated, time: .omitted) ?? "NEW")
                    VocabInfoLabel(title: "Next Review", value: item.nextReviewAt?.formatted(date: .abbreviated, time: .omitted) ?? "READY")
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    private var masteryDescription: String {
        switch item.masteryLevel {
        case 0: return "New"
        case 1...2: return "Learning"
        case 3...4: return "Reviewing"
        case 5: return "Mastered"
        default: return "Learning"
        }
    }
    
    private var masteryColor: Color {
        switch item.masteryLevel {
        case 0: return .gray.opacity(0.4)
        case 1...2: return Theme.coral
        case 3...4: return Theme.softTeal
        case 5: return Theme.primaryTeal
        default: return Theme.primaryTeal
        }
    }
}

struct BadgeView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

struct VocabInfoLabel: View {
    let title: String
    let value: String
    var alignment: HorizontalAlignment = .leading
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
        }
    }
}

struct EditorialCard<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title.uppercased())
                .font(.system(size: 12, weight: .black))
                .foregroundStyle(.secondary.opacity(0.6))
                .kerning(1.2)
            
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(32)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: Color.black.opacity(0.04), radius: 20, x: 0, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 32)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
    }
}

struct BandScoreBadge: View {
    let score: Double
    
    var body: some View {
        VStack(spacing: 2) {
            Text("IELTS")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white.opacity(0.8))
            Text(String(format: "%.1f", score))
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(.white)
            Text("BAND")
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white.opacity(0.8))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.amber)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Theme.amber.opacity(0.2), radius: 15, y: 10)
    }
}

struct CircularProgressView: View {
    let progress: Double
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.08), lineWidth: 10)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}


#Preview {
    let sample = VocabularyItem(word: "Serendipity", definition: "The occurrence and development of events by chance in a happy or beneficial way.", exampleSentence: "We found the restaurant by pure serendipity.", partOfSpeech: "Noun", bandScore: 8.5, category: "Academic")
    return NavigationStack {
        VocabDetailView(item: sample)
    }
}
