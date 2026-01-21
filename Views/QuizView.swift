import SwiftUI
import SwiftData

struct QuizView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: QuizViewModel
    let selectedCategory: String
    
    init(selectedCategory: String = "All", modelContext: ModelContext? = nil) {
        self.selectedCategory = selectedCategory
        _viewModel = State(initialValue: QuizViewModel(modelContext: modelContext))
    }
    
    var body: some View {
        ZStack {
            DashboardBackground()
            
            VStack {
                if viewModel.isGameOver {
                    quizResultView
                } else if let question = viewModel.currentQuestion {
                    premiumQuizQuestionView(for: question)
                } else {
                    loadingOrEmptyView
                }
            }
        }
        .navigationTitle("Quiz (\(selectedCategory))")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onAppear {
            viewModel.modelContext = modelContext
            viewModel.startQuiz(category: selectedCategory)
        }
    }
    
    @ViewBuilder
    private func premiumQuizQuestionView(for question: QuizViewModel.QuizQuestion) -> some View {
        VStack(spacing: 40) {
            // Editorial Progress Header
            VStack(spacing: 12) {
                HStack {
                    Text("QUESTION \(viewModel.totalQuestions)")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.secondary.opacity(0.6))
                        .kerning(1.5)
                    Spacer()
                    Text("10")
                        .font(.system(size: 12, weight: .black))
                        .foregroundStyle(.secondary.opacity(0.3))
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.secondary.opacity(0.1))
                        Capsule()
                            .fill(Theme.primaryAccent)
                            .frame(width: geo.size.width * CGFloat(Double(min(10, viewModel.totalQuestions))/10.0))
                    }
                }
                .frame(height: 8)
            }
            .padding(.horizontal, 40)
            .padding(.top, 40)
            
            // The Question Card
            VStack(spacing: 16) {
                Text("EXPRESSION MEANING")
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.secondary.opacity(0.4))
                    .kerning(2.0)
                
                Text(question.word.word)
                    .font(.system(size: 56, weight: .black, design: .rounded))
                    .foregroundStyle(Theme.primaryGradient)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(48)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 48))
            .shadow(color: Color.black.opacity(0.06), radius: 30, x: 0, y: 15)
            .overlay(
                RoundedRectangle(cornerRadius: 48)
                    .stroke(Theme.cardBorder, lineWidth: 1.5)
            )
            .padding(.horizontal, 40)
            
            // Option Buttons
            VStack(spacing: 16) {
                ForEach(0..<question.options.count, id: \.self) { index in
                    ChoiceButton(title: question.options[index]) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewModel.submitAnswer(at: index)
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private var quizResultView: some View {
        ScrollView {
            VStack(spacing: 40) {
                ZStack {
                    Circle().fill(Theme.primaryGradient.opacity(0.1)).frame(width: 140, height: 140)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Theme.primaryAccent)
                        .shadow(color: Theme.primaryAccent.opacity(0.3), radius: 15, y: 10)
                }
                .padding(.top, 40)
                
                VStack(spacing: 12) {
                    Text(viewModel.score >= 8 ? "OUTSTANDING!" : "WELL DONE!")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundStyle(Theme.primaryGradient)
                    Text("Your active recall session is complete.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                HStack(spacing: 24) {
                    ResultStatCard(title: "SCORE", value: "\(viewModel.score)/10", icon: "star.fill", color: Theme.amber)
                    ResultStatCard(title: "SUCCESS", value: "\(viewModel.score * 10)%", icon: "target", color: Theme.primaryTeal)
                }
                .padding(.horizontal, 40)
                
                if !viewModel.incorrectAttempts.isEmpty {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Review your errors")
                            .font(.title3.bold())
                            .padding(.horizontal, 40)
                        
                        VStack(spacing: 12) {
                            ForEach(viewModel.incorrectAttempts) { attempt in
                                IncorrectRow(attempt: attempt)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                }
                
                Button(action: { viewModel.startQuiz(category: selectedCategory) }) {
                    Text("TAKE ANOTHER TEST")
                        .font(.system(size: 13, weight: .black))
                        .kerning(1.5)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(Theme.primaryAccent)
                        .clipShape(Capsule())
                        .shadow(color: Theme.primaryAccent.opacity(0.3), radius: 10, y: 8)
                }
                .buttonStyle(.plain)
                .padding(.top, 20)
                .padding(.bottom, 60)
            }
        }
    }
    
    private var loadingOrEmptyView: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 80))
                .foregroundStyle(.secondary.opacity(0.3))
            
            VStack(spacing: 8) {
                Text("Not enough data")
                    .font(.title2.bold())
                Text("You need at least 4 words in your bank to generate a quiz.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }
        }
    }
}

struct ChoiceButton: View {
    let title: String
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary.opacity(0.8))
                Spacer()
                indicator
            }
            .padding(24)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(color: isHovered ? Color.black.opacity(0.06) : Theme.cardShadow, 
                    radius: isHovered ? 15 : 8, x: 0, y: 4)
            .overlay(buttonBorder)
            .scaleEffect(isHovered ? 1.01 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }
    
    @ViewBuilder
    private var indicator: some View {
        ZStack {
            if isHovered {
                Circle()
                    .stroke(Theme.primaryAccent.opacity(0.5), lineWidth: 2)
                Circle()
                    .fill(Theme.primaryAccent)
                    .frame(width: 12, height: 12)
            } else {
                Circle()
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 2)
            }
        }
        .frame(width: 24, height: 24)
    }
    
    @ViewBuilder
    private var buttonBorder: some View {
        if isHovered {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Theme.primaryAccent.opacity(0.3), lineWidth: 1.5)
        } else {
            RoundedRectangle(cornerRadius: 24)
                .stroke(Theme.cardBorder, lineWidth: 1.5)
        }
    }
}

struct ResultStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.title3)
            }
            
            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                Text(title)
                    .font(.system(size: 10, weight: .black))
                    .foregroundStyle(.secondary.opacity(0.6))
                    .kerning(1.0)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .shadow(color: Theme.cardShadow, radius: 15, x: 0, y: 10)
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(Theme.cardBorder, lineWidth: 1))
    }
}



struct IncorrectRow: View {
    let attempt: QuizViewModel.IncorrectAttempt
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(attempt.word)
                    .font(.headline)
                    .foregroundStyle(Theme.vibrantRed)
                Spacer()
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Theme.vibrantRed.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Label {
                    Text(attempt.definition)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                } icon: {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Theme.primaryTeal)
                }
                
                Label {
                    Text(attempt.chosenAnswer)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .strikethrough()
                } icon: {
                    Image(systemName: "multiply")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Theme.cardShadow, radius: 8, x: 0, y: 4)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Theme.cardBorder, lineWidth: 1))
    }
}


#Preview {
    QuizView()
}
