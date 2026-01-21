import SwiftUI
import SwiftData

struct VocabBankView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \VocabularyItem.word) private var items: [VocabularyItem]
    @State private var searchText = ""
    @State private var showingAddSheet = false
    
    @State private var selectedCategory = "All"
    @State private var showingImporter = false
    @State private var importStatusMessage = ""
    @State private var showingStatusAlert = false
    @State private var isHoveringImport = false
    @FocusState private var isSearchFocused: Bool
    
    var categories: [String] {
        let allCategories = Set(items.map { $0.category })
        return ["All"] + allCategories.sorted()
    }
    
    var filteredItems: [VocabularyItem] {
        var baseItems = items
        
        if selectedCategory != "All" {
            baseItems = baseItems.filter { $0.category == selectedCategory }
        }
        
        if searchText.isEmpty {
            return baseItems
        } else {
            return baseItems.filter { $0.word.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()
                
                VStack(spacing: 0) {
                    // Premium Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(isSearchFocused ? Theme.primaryAccent : .secondary)
                        TextField("Search keywords...", text: $searchText)
                            .textFieldStyle(.plain)
                            .focused($isSearchFocused)
                            .onSubmit { isSearchFocused = false }
                    }
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: isSearchFocused ? Theme.primaryAccent.opacity(0.1) : Theme.cardShadow, 
                            radius: isSearchFocused ? 10 : 4, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSearchFocused ? Theme.primaryAccent.opacity(0.5) : Theme.cardBorder, lineWidth: 1.5)
                    )
                    .padding(.horizontal)
                    .padding(.top)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isSearchFocused = true
                        #if os(macOS)
                        NSApp.activate(ignoringOtherApps: true)
                        #endif
                    }
                    
                    // Category Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { category in
                                CategoryChip(
                                    title: category,
                                    isSelected: selectedCategory == category,
                                    action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedCategory = category
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    
                    if items.isEmpty {
                        emptyStateView
                    } else if filteredItems.isEmpty {
                        ContentUnavailableView.search
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredItems) { item in
                                    NavigationLink {
                                        VocabDetailView(item: item)
                                    } label: {
                                        VocabRowView(item: item)
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            modelContext.delete(item)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
            .navigationTitle("Vocab Bank")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    HStack(spacing: 2) {
                        Button(action: { showingImporter = true }) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(isHoveringImport ? Theme.primaryAccent : .secondary)
                                .frame(width: 30, height: 30)
                                .background(isHoveringImport ? Theme.primaryAccent.opacity(0.08) : Color.clear)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .help("Import CSV")
                        .onHover { isHoveringImport = $0 }
                        
                        Rectangle()
                            .fill(Color.secondary.opacity(0.15))
                            .frame(width: 1, height: 14)
                            .padding(.horizontal, 2)
                        
                        Button(action: { showingAddSheet = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(Theme.primaryAccent)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .help("Add Word")
                    }
                    .padding(3)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(Theme.cardBorder, lineWidth: 0.5)
                    )
                }
            }
            .fileImporter(
                isPresented: $showingImporter,
                allowedContentTypes: [.commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        do {
                            let count = try CSVImporter.shared.importCSV(from: url, modelContext: modelContext)
                            importStatusMessage = "Successfully imported \(count) words!"
                            showingStatusAlert = true
                        } catch {
                            importStatusMessage = "Import failed: \(error.localizedDescription)"
                            showingStatusAlert = true
                        }
                    }
                case .failure(let error):
                    importStatusMessage = "File selection failed: \(error.localizedDescription)"
                    showingStatusAlert = true
                }
            }
            .alert("CSV Import", isPresented: $showingStatusAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importStatusMessage)
            }
            .sheet(isPresented: $showingAddSheet) {
                AddVocabView()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Theme.primaryGradient.opacity(0.1))
                    .frame(width: 120, height: 120)
                Image(systemName: "book.pages")
                    .font(.system(size: 48))
                    .foregroundStyle(Theme.primaryGradient)
            }
            
            VStack(spacing: 8) {
                Text("Your bank is empty")
                    .font(.title2.bold())
                Text("Start your IELTS preparation by adding your first vocabulary word.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            Button(action: { showingAddSheet = true }) {
                Text("Add First Word")
                    .font(.headline)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(Color.accentColor) // Simplified color
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                    .shadow(color: Color.accentColor.opacity(0.2), radius: 10, y: 5) // Simplified color
            }
            .buttonStyle(.plain)
        }
        .frame(maxHeight: .infinity)
    }

    private var groupedItems: [String: [VocabularyItem]] {
        Dictionary(grouping: filteredItems) { String($0.word.prefix(1)).uppercased() }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredItems[index])
            }
        }
    }
}

struct VocabRowView: View {
    let item: VocabularyItem
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 20) {
            masteryIndicator
            mainContent
            Spacer()
            trailingContent
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: isHovered ? Color.black.opacity(0.08) : Theme.cardShadow, radius: isHovered ? 12 : 8, x: 0, y: 4)
        .overlay(rowBorder)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
        .padding(.horizontal)
    }
    
    private var masteryIndicator: some View {
        Capsule()
            .fill(masteryColor)
            .frame(width: 4, height: 40)
    }
    
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.word)
                .font(.system(.title3, design: .rounded, weight: .bold))
            Text(item.definition)
                .font(.subheadline)
                .lineLimit(1)
                .foregroundStyle(.secondary)
        }
    }
    
    private var trailingContent: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Text(item.partOfSpeech)
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Theme.primaryAccent.opacity(0.1))
                .foregroundStyle(Theme.primaryAccent)
                .clipShape(Capsule())
            
            if let score = item.bandScore {
                bandScoreLabel(score)
            }
        }
    }
    
    private func bandScoreLabel(_ score: Double) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.system(size: 8))
            Text("Band \(String(format: "%.1f", score))")
                .font(.system(size: 10, weight: .heavy))
        }
        .foregroundStyle(Theme.amber)
    }
    
    @ViewBuilder
    private var rowBorder: some View {
        if isHovered {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.primaryAccent.opacity(0.3), lineWidth: 1)
        } else {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Theme.cardBorder, lineWidth: 1)
        }
    }
    
    private var masteryColor: Color {
        switch item.masteryLevel {
        case 4...: return Theme.primaryTeal
        case 2...3: return Theme.softTeal
        default: return Theme.coral.opacity(0.3)
        }
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Theme.primaryAccent : Color.gray.opacity(0.1))
                .foregroundStyle(isSelected ? .white : .secondary)
                .clipShape(Capsule())
                .shadow(color: isSelected ? Theme.primaryAccent.opacity(0.3) : .clear, radius: 5, y: 2)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VocabBankView()
}
