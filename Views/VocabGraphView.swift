import SwiftUI
import SwiftData

struct VocabGraphView: View {
    @Query private var items: [VocabularyItem]
    @State private var hoveredItem: VocabularyItem?
    
    // Group items by category for the visualization
    private var groupedItems: [String: [VocabularyItem]] {
        Dictionary(grouping: items) { $0.category }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                DashboardBackground()
                
                if items.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 0) {
                        // Graph Legend
                        HStack(spacing: 24) {
                            LegendItem(label: "New", color: .gray.opacity(0.2))
                            LegendItem(label: "Learning", color: Theme.coral)
                            LegendItem(label: "Reviewing", color: Theme.softTeal)
                            LegendItem(label: "Mastered", color: Theme.primaryTeal)
                        }
                        .padding(24)
                        .background(Theme.glassBackground)
                        .clipShape(Capsule())
                        .padding(.top, 24)
                        
                        graphCanvas
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                
                // Detailed overlay when an item is hovered
                VStack {
                    Spacer()
                    if let item = items.first(where: { it in hoveredItem?.word == it.word }) {
                        wordDetailOverlay(for: item)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Vocabulary Map")
        }
    }
    
    private var graphCanvas: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let categories = Array(groupedItems.keys).sorted()
                let totalCategories = CGFloat(categories.count)
                let baseRadius = min(size.width, size.height) * 0.3
                
                let time = timeline.date.timeIntervalSinceReferenceDate
                
                for (index, category) in categories.enumerated() {
                    let catProgress = CGFloat(index) / totalCategories
                    let angle = catProgress * 2.0 * .pi
                    let catX = center.x + cos(angle) * (baseRadius + 20.0)
                    let catY = center.y + sin(angle) * (baseRadius + 20.0)
                    let categoryCenter = CGPoint(x: catX, y: catY)
                    
                    let catSize: CGFloat = 48.0
                    let catRect = CGRect(x: categoryCenter.x - 24.0, y: categoryCenter.y - 24.0, width: catSize, height: catSize)
                    context.fill(Path(ellipseIn: catRect), with: .color(Theme.primaryAccent.opacity(0.05)))
                    context.stroke(Path(ellipseIn: catRect), with: .color(Theme.primaryAccent.opacity(0.2)), lineWidth: 1.5)
                    
                    let label = String(category.prefix(1)).uppercased()
                    let txt = Text(label).font(.system(size: 16, weight: .black, design: .rounded)).foregroundStyle(Theme.primaryAccent)
                    context.draw(txt, in: catRect)
                    
                    // Draw node for each word
                    if let words = groupedItems[category] {
                        let totalWords = CGFloat(words.count)
                        for (wIndex, word) in words.enumerated() {
                            let pulsate = sin(time * 2.0 + Double(wIndex)) * 2.0
                            let wProgress = CGFloat(wIndex) / totalWords
                            let wAngle = wProgress * 2.0 * .pi + CGFloat(time * 0.1)
                            
                            let wDist = 40.0 + CGFloat(word.masteryLevel) * 8.0 + CGFloat(pulsate)
                            let nodeX = categoryCenter.x + cos(wAngle) * wDist
                            let nodeY = categoryCenter.y + sin(wAngle) * wDist
                            let nodePos = CGPoint(x: nodeX, y: nodeY)
                            
                            let nodeSize = 10.0 + CGFloat(word.masteryLevel) * 3.0
                            let nodeRect = CGRect(x: nodePos.x - nodeSize/2.0, y: nodePos.y - nodeSize/2.0, width: nodeSize, height: nodeSize)
                            
                            let color = getColor(for: word.masteryLevel)
                            context.fill(Path(ellipseIn: nodeRect), with: .color(color.opacity(0.8)))
                            
                            if word.masteryLevel == 5 {
                                context.stroke(Path(ellipseIn: nodeRect.insetBy(dx: -2, dy: -2)), with: .color(color.opacity(0.3)), lineWidth: 1.0)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func getColor(for level: Int) -> Color {
        switch level {
        case 0: return .gray.opacity(0.2)
        case 1...2: return Theme.coral
        case 3...4: return Theme.softTeal
        case 5: return Theme.primaryTeal
        default: return Theme.primaryTeal
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "circle.grid.3x3.fill")
                .font(.system(size: 80))
                .foregroundStyle(.secondary.opacity(0.2))
            Text("Visualizing your journey...")
                .font(.headline)
                .foregroundStyle(.secondary)
            Text("Add more words to see your vocabulary map grow.")
                .font(.subheadline)
                .foregroundStyle(.secondary.opacity(0.8))
        }
    }
    
    @ViewBuilder
    private func wordDetailOverlay(for item: VocabularyItem) -> some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Theme.primaryAccent.opacity(0.1))
                    .frame(width: 44, height: 44)
                Text(item.word.prefix(1).uppercased())
                    .font(.headline)
                    .foregroundStyle(Theme.primaryAccent)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.word)
                    .font(.headline)
                Text(item.definition)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(20)
        .background(Theme.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Theme.cardBorder, lineWidth: 1))
        .padding(40)
    }
}

struct LegendItem: View {
    let label: String
    let color: Color
    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(color).frame(width: 10, height: 10)
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}
