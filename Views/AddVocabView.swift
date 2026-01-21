import SwiftUI
import SwiftData

struct AddVocabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var word = ""
    @State private var definition = ""
    @State private var example = ""
    @State private var partOfSpeech = "Noun"
    @State private var bandScore: Double = 7.0
    @State private var category = "Academic"
    @State private var synonyms = ""
    @State private var antonyms = ""
    @State private var collocations = ""

    
    let partsOfSpeech = ["Noun", "Verb", "Adjective", "Adverb", "Idiom", "Phrasal Verb"]
    let categories = ["Academic", "Environment", "Technology", "Health", "Education", "Society", "Work"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Section: Basic Detail
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Basic Detail")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            VStack(spacing: 16) {
                                CustomTextField(label: "Word / Phrase", text: $word, placeholder: "e.g. Epiphany")
                                CustomTextEditor(label: "Definition", text: $definition, placeholder: "Meaning of the word...")
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Theme.cardShadow, radius: 10, x: 0, y: 5)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardBorder, lineWidth: 1))
                        }
                        
                        // Section: Usage
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Usage & Context")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Part of Speech")
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Picker("", selection: $partOfSpeech) {
                                        ForEach(partsOfSpeech, id: \.self) { Text($0) }
                                    }
                                    .pickerStyle(.menu)
                                }
                                
                                Divider()
                                
                                CustomTextEditor(label: "Example Sentence", text: $example, placeholder: "How is it used in a sentence?")
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Theme.cardShadow, radius: 10, x: 0, y: 5)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardBorder, lineWidth: 1))
                        }
                        
                        // Section: IELTS Info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("IELTS Specifics")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            VStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text("Target Band Score")
                                            .font(.subheadline.bold())
                                        Spacer()
                                        Text(String(format: "%.1f", bandScore))
                                            .font(.title3.bold())
                                            .foregroundStyle(Theme.primaryAccent)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 4)
                                            .background(Theme.primaryAccent.opacity(0.1))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                    }
                                    Slider(value: $bandScore, in: 0...9, step: 0.5)
                                        .tint(Theme.primaryAccent)
                                }
                                
                                Divider()
                                
                                HStack {
                                    Text("Category")
                                        .font(.subheadline.bold())
                                    Spacer()
                                    Picker("", selection: $category) {
                                        ForEach(categories, id: \.self) { Text($0) }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Theme.cardShadow, radius: 10, x: 0, y: 5)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardBorder, lineWidth: 1))
                        }
                        
                        // Section: Advanced Detail
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Advanced Content")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            VStack(spacing: 16) {
                                CustomTextField(label: "Synonyms", text: $synonyms, placeholder: "Separated by commas")
                                CustomTextField(label: "Antonyms", text: $antonyms, placeholder: "Separated by commas")
                                CustomTextEditor(label: "Collocations", text: $collocations, placeholder: "Common word pairings...")
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Theme.cardShadow, radius: 10, x: 0, y: 5)
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardBorder, lineWidth: 1))
                        }
                    }
                    .padding(32)
                }
            }
            .navigationTitle("New Vocabulary")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: saveWord) {
                        Text("Save Word")
                            .bold()
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background {
                                if word.isEmpty || definition.isEmpty {
                                    Color.gray.opacity(0.3)
                                } else {
                                    Theme.primaryAccent
                                }
                            }
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                    .disabled(word.isEmpty || definition.isEmpty)
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 750)
    }
    
    private func saveWord() {
        let newItem = VocabularyItem(
            word: word,
            definition: definition,
            exampleSentence: example,
            partOfSpeech: partOfSpeech,
            bandScore: bandScore,
            category: category,
            synonyms: synonyms,
            antonyms: antonyms,
            collocations: collocations
        )

        modelContext.insert(newItem)
        dismiss()
    }
}

struct CustomTextField: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline.bold())
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .padding(14)
                .background(Color.gray.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.05), lineWidth: 1))
        }
    }
}

struct CustomTextEditor: View {
    let label: String
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline.bold())
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.secondary.opacity(0.4))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                }
                TextEditor(text: $text)
                    .frame(minHeight: 100)
                    .scrollContentBackground(.hidden)
                    .padding(8)
                    .background(Color.gray.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.05), lineWidth: 1))
            }
        }
    }
}

#Preview {
    AddVocabView()
}
