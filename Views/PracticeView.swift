import SwiftUI
import SwiftData

struct PracticeView: View {
    @Query private var items: [VocabularyItem]
    @State private var selectedCategory = "All"
    
    var categories: [String] {
        let allCategories = Set(items.map { $0.category })
        return ["All"] + allCategories.sorted()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()
                
                ScrollView {
                    VStack(spacing: 30) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ready to practice?")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                            Text("Master your vocabulary with these modes.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top)
                        
                        // Targeted Study Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Targeted Study")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            TargetedStudyPicker(selectedCategory: $selectedCategory)
                        }
                        
                        VStack(spacing: 20) {
                            NavigationLink {
                                FlashcardPracticeView(selectedCategory: selectedCategory)
                            } label: {
                                PremiumPracticeCard(
                                    title: "Daily Flashcards",
                                    subtitle: "Review scheduled words based on SRS algorithm.",
                                    icon: "cards.fill",
                                    color: Theme.amber
                                )
                            }
                            
                            NavigationLink {
                                QuizView(selectedCategory: selectedCategory)
                            } label: {
                                PremiumPracticeCard(
                                    title: "Vocabulary Quiz",
                                    subtitle: "Quick 10-question test for active recall.",
                                    icon: "checklist.checked",
                                    color: Theme.primaryAccent
                                )
                            }
                            
                            // Placeholder for future mode
                            PremiumPracticeCard(
                                title: "Dictation Master",
                                subtitle: "Coming soon: Type what you hear.",
                                icon: "mic.fill",
                                color: Theme.softTeal.opacity(0.5)
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Practice")
        }
    }
}

struct PremiumPracticeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 24) {
            iconView
            labelsView
            Spacer()
            arrowView
        }
        .padding(32)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 28))
        .shadow(color: isHovered ? Color.black.opacity(0.08) : Theme.cardShadow, 
                radius: isHovered ? 20 : 12, x: 0, y: 8)
        .overlay(cardBorder)
        .scaleEffect(isHovered ? 1.015 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }
    
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: 64, height: 64)
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(color)
        }
    }
    
    private var labelsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var arrowView: some View {
        Image(systemName: "arrow.right.circle.fill")
            .font(.title2)
            .foregroundStyle(color.opacity(isHovered ? 1.0 : 0.4))
            .offset(x: isHovered ? 5 : 0)
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 28)
            .stroke(isHovered ? color.opacity(0.3) : Theme.cardBorder, lineWidth: 1.5)
    }
}


struct FlashcardPracticeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allItems: [VocabularyItem]
    @State private var viewModel = PracticeViewModel()
    @State private var degree: Double = 0
    @State private var isFlipped: Bool = false
    let selectedCategory: String
    
    var body: some View {
        ZStack {
            DashboardBackground()
            
            VStack {
                if viewModel.isSessionComplete && !viewModel.wordsToReview.isEmpty {
                    sessionCompleteView
                } else if let word = viewModel.currentWord {
                    premiumFlashcardView(for: word)
                } else {
                    EmptyPracticeView(
                        isBankEmpty: allItems.isEmpty,
                        category: selectedCategory,
                        action: { viewModel.fetchWords(category: selectedCategory) }
                    )
                }
            }
        }
        .navigationTitle("Daily Review (\(selectedCategory))")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.fetchWords(category: selectedCategory)
        }
    }
    
    @ViewBuilder
    private func premiumFlashcardView(for item: VocabularyItem) -> some View {
        VStack(spacing: 40) {
            // Progress tracker
            VStack(spacing: 8) {
                HStack {
                    Text("Word \(viewModel.currentWordIndex + 1) of \(viewModel.wordsToReview.count)")
                        .font(.subheadline.bold())
                    Spacer()
                    Text("\(Int(Double(viewModel.currentWordIndex + 1)/Double(viewModel.wordsToReview.count)*100))%")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
                ProgressView(value: Double(viewModel.currentWordIndex + 1), total: Double(viewModel.wordsToReview.count))
                    .tint(Theme.primaryAccent)
            }
            .padding(.horizontal, 24)

            // The Animated Flashcard
            ZStack {
                // Front
                FlashcardFace(word: item.word, partOfSpeech: item.partOfSpeech, side: .front)
                    .rotation3DEffect(.degrees(degree), axis: (x: 0, y: 1, z: 0))
                    .opacity(isFlipped ? 0 : 1)
                
                // Back
                FlashcardFace(word: item.word, definition: item.definition, example: item.exampleSentence, side: .back)
                    .rotation3DEffect(.degrees(degree + 180), axis: (x: 0, y: 1, z: 0))
                    .opacity(isFlipped ? 1 : 0)
            }
            .frame(maxWidth: 400, maxHeight: 450)
            .onTapGesture {
                flipCard()
            }
            .padding(.horizontal, 24)
            
            // Interaction Buttons
            if isFlipped {
                VStack(spacing: 24) {
                    Text("Did you remember it?")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    HStack(spacing: 16) {
                        PremiumRatingButton(title: "Forgot", sub: "Reset", color: Theme.vibrantRed) {
                            submitAnswer(0)
                        }
                        PremiumRatingButton(title: "Hard", sub: "Shorten", color: Theme.amber) {
                            submitAnswer(3)
                        }
                        PremiumRatingButton(title: "Easy", sub: "Extend", color: Theme.lightGreen) {
                            submitAnswer(5)
                        }
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.horizontal, 24)
            } else {
                Text("Tap to reveal answer")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 20)
            }
            
            Spacer()
        }
    }
    
    private func flipCard() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) {
            isFlipped.toggle()
            degree += 180
            viewModel.isShowingAnswer = isFlipped
        }
    }
    
    private func submitAnswer(_ quality: Int) {
        viewModel.submitAnswer(quality: quality)
        // Reset card state for next word
        withAnimation(.none) {
            isFlipped = false
            degree = 0
            viewModel.isShowingAnswer = false
        }
    }
    
    private var sessionCompleteView: some View {
        VStack(spacing: 30) {
            ZStack {
                Circle().fill(Theme.lightGreen.opacity(0.1)).frame(width: 120, height: 120)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(Theme.lightGreen)
            }
            
            VStack(spacing: 12) {
                Text("Excellent Work!")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("You've cleared all your reviews for today.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: { viewModel.fetchWords() }) {
                Text("Finish Session")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(Theme.primaryAccent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}

enum FlashcardSide { case front, back }

struct FlashcardFace: View {
    let word: String
    var definition: String = ""
    var example: String = ""
    var partOfSpeech: String = ""
    let side: FlashcardSide
    
    var body: some View {
        VStack(spacing: 32) {
            if side == .front {
                Spacer()
                Text(word)
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.primaryAccent)
                    .multilineTextAlignment(.center)
                
                Text(partOfSpeech.uppercased())
                    .font(.system(size: 12, weight: .black))
                    .kerning(1.5)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.secondary.opacity(0.05))
                    .clipShape(Capsule())
                Spacer()
                
                Label("Tap to flip", systemImage: "hand.tap.fill")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(.secondary.opacity(0.4))
            } else {
                VStack(spacing: 24) {
                    Text(word)
                        .font(.headline)
                        .foregroundStyle(.secondary.opacity(0.6))
                    
                    Divider().opacity(0.1)
                    
                    Text(definition)
                        .font(.system(size: 24, weight: .medium, design: .serif))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal)
                    
                    if !example.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "quote.opening")
                                .font(.caption)
                                .foregroundStyle(Theme.primaryAccent.opacity(0.3))
                            Text(example)
                                .italic()
                                .font(.system(size: 16, design: .serif))
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 32)
                    }
                }
                .padding(.top, 40)
                Spacer()
            }
            
            Button(action: { AudioService.shared.speak(word) }) {
                Image(systemName: "speaker.wave.3.fill")
                    .font(.title3)
                    .padding(12)
                    .background(Theme.primaryAccent.opacity(0.1))
                    .foregroundStyle(Theme.primaryAccent)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 48))
        .shadow(color: Color.black.opacity(0.06), radius: 30, x: 0, y: 15)
        .overlay(
            RoundedRectangle(cornerRadius: 48)
                .stroke(Theme.cardBorder, lineWidth: 1.5)
        )
    }
}

struct EmptyPracticeView: View {
    let isBankEmpty: Bool
    let category: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: isBankEmpty ? "book.closed.fill" : "sparkle.square.fill.on.square")
                .font(.system(size: 80))
                .foregroundStyle(Theme.primaryAccent)
            
            VStack(spacing: 8) {
                Text(isBankEmpty ? "Your bank is empty" : "Peace and quiet")
                    .font(.title.bold())
                Text(isBankEmpty ? 
                     "Add some words to the bank first to start practicing." : 
                     "No words in \(category) scheduled for review right now.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            Button(action: action) {
                Text(isBankEmpty ? "Go to Bank" : "Check Again")
                    .font(.headline)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(Theme.primaryAccent.opacity(0.1))
                    .foregroundStyle(Theme.primaryAccent)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }
}

struct PremiumRatingButton: View { // Added struct declaration
    let title: String
    let sub: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(sub)
                    .font(.system(size: 10, weight: .bold))
                    .opacity(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: color.opacity(0.1), radius: 5, x: 0, y: 5)
        }
        .buttonStyle(.plain)
    }
}


struct TargetedStudyPicker: View {
    @Query private var items: [VocabularyItem]
    @Binding var selectedCategory: String
    
    var categories: [String] {
        let allCategories = Set(items.map { $0.category })
        return ["All"] + allCategories.sorted()
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                    }) {
                        Text(category)
                            .font(.subheadline.bold())
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Theme.primaryAccent : Color.gray.opacity(0.1))
                            .foregroundStyle(selectedCategory == category ? .white : .secondary)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    PracticeView()
}
