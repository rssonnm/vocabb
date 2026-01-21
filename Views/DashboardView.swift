import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var items: [VocabularyItem]
    @State private var showingSettings = false
    
    private var wordsLearnedToday: Int {
        let calendar = Calendar.current
        return items.filter { calendar.isDateInToday($0.createdAt) }.count
    }
    
    private var wordsReviewedToday: Int {
        let calendar = Calendar.current
        return items.filter { 
            if let lastReview = $0.lastReviewedAt {
                return calendar.isDateInToday(lastReview)
            }
            return false
        }.count
    }
    
    private var currentStreak: Int {
        let calendar = Calendar.current
        let reviewDates = Set(items.compactMap { $0.lastReviewedAt }.map { calendar.startOfDay(for: $0) })
        
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        
        if !reviewDates.contains(checkDate) {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        while reviewDates.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        return streak
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Mesh/Radial Gradient Effect
                DashboardBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header Section
                        headerSection
                        
                        // Activity Heatmap
                        ActivityHeatmapView()

                        // Main Stats Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.standardPadding) {
                            PremiumStatCard(title: "Total Words", value: "\(items.count)", icon: "book.closed.fill", accent: Theme.primaryAccent)
                            PremiumStatCard(title: "To Review", value: "\(items.filter { ($0.nextReviewAt ?? Date()) <= Date() }.count)", icon: "clock.fill", accent: Theme.warningAccent)
                            PremiumStatCard(title: "Streak", value: "\(currentStreak) Days", icon: "flame.fill", accent: Theme.burntOrange)
                            PremiumStatCard(title: "Mastery", value: "\(Int(successRate))%", icon: "chart.bar.fill", accent: Theme.successAccent)
                        }
                        
                        // Analysis Row
                        HStack(alignment: .top, spacing: Theme.standardPadding) {
                            MasteryBreakdownCard(items: items)
                            ReviewForecastCard(items: items)
                        }
                        
                        // Daily Goal
                        DailyGoalCard(progress: wordsLearnedToday, goal: 20)
                        
                        // Recent Activity
                        recentActivitySection
                    }
                    .padding(32)
                }
            }
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.secondary)
                            .frame(width: 30, height: 30)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private var successRate: Double {
        let mastered = items.filter { $0.masteryLevel >= 4 }.count
        return items.isEmpty ? 0 : (Double(mastered) / Double(items.count) * 100)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Welcome back!")
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Text("Continue your journey to Band 8.0+")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }
    
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Recent Vocabulary")
                .font(.title2.bold())
            
            if items.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary.opacity(0.3))
                    Text("No words added yet.")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Start by adding vocabulary in the Bank tab.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .background(Theme.glassBackground)
                .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
                .overlay(RoundedRectangle(cornerRadius: Theme.cardCornerRadius).stroke(Theme.cardBorder, lineWidth: 1))
            } else {
                VStack(spacing: 12) {
                    ForEach(items.suffix(3).reversed()) { item in
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Theme.primaryGradient.opacity(0.1))
                                    .frame(width: 44, height: 44)
                                Text(item.word.prefix(1).uppercased())
                                    .font(.headline)
                                    .foregroundStyle(Theme.primaryGradient)
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
                            Text(item.partOfSpeech)
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Theme.primaryAccent.opacity(0.1))
                                .foregroundStyle(Theme.primaryAccent)
                                .clipShape(Capsule())
                        }
                        .padding()
                        .background(Theme.glassBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.cardBorder, lineWidth: 1))
                    }
                }
            }
        }
    }
}

struct DashboardBackground: View {
    var body: some View {
        Theme.pureWhite.ignoresSafeArea()
    }
}

struct PremiumStatCard: View {
    let title: String
    let value: String
    let icon: String
    let accent: Color
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            statIcon
            statLabels
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.standardPadding)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        .shadow(color: isHovered ? Color.black.opacity(0.08) : Theme.cardShadow, 
                radius: isHovered ? 15 : 10, x: 0, y: 5)
        .overlay(cardBorder)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isHovered = hovering
            }
        }
    }
    
    private var statIcon: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.15))
                .frame(width: 48, height: 48)
            Image(systemName: icon)
                .foregroundStyle(accent)
                .font(.title3)
        }
    }
    
    private var statLabels: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private var cardBorder: some View {
        if isHovered {
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .stroke(accent.opacity(0.3), lineWidth: 1.5)
        } else {
            RoundedRectangle(cornerRadius: Theme.cardCornerRadius)
                .stroke(Theme.cardBorder, lineWidth: 1.5)
        }
    }
}

struct DailyGoalCard: View {
    let progress: Int
    let goal: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            headerRow
            progressContent
        }
        .padding(Theme.standardPadding)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        .shadow(color: Theme.cardShadow, radius: 10, y: 5)
        .overlay(RoundedRectangle(cornerRadius: Theme.cardCornerRadius).stroke(Theme.cardBorder, lineWidth: 1))
    }
    
    private var headerRow: some View {
        HStack {
            Text("Daily Progress")
                .font(.headline)
            Spacer()
            Text("\(Int(min(1.0, Double(progress)/Double(goal))*100))%")
                .font(.subheadline.bold())
                .foregroundStyle(Theme.primaryAccent)
        }
    }
    
    private var progressContent: some View {
        VStack(spacing: 12) {
            HStack {
                Label("\(progress) words learned today", systemImage: "sparkles")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Goal: \(goal)")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary.opacity(0.6))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.1))
                    Capsule()
                        .fill(Theme.primaryAccent)
                        .frame(width: geo.size.width * CGFloat(min(1.0, Double(progress)/Double(goal))))
                }
            }
            .frame(height: 10)
        }
    }
}

struct MasteryBreakdownCard: View {
    let items: [VocabularyItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mastery levels")
                .font(.headline)
            
            VStack(spacing: 8) {
                LevelRow(label: "Mastered", count: items.filter { $0.masteryLevel >= 4 }.count, color: Theme.primaryTeal)
                LevelRow(label: "Learning", count: items.filter { $0.masteryLevel > 0 && $0.masteryLevel < 4 }.count, color: Theme.softTeal)
                LevelRow(label: "New", count: items.filter { $0.masteryLevel == 0 }.count, color: .gray.opacity(0.2))
            }
        }
        .padding(Theme.standardPadding)
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(Theme.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardCornerRadius).stroke(Theme.cardBorder, lineWidth: 1))
    }
}

struct LevelRow: View {
    let label: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.system(size: 13)).foregroundStyle(.secondary)
            Spacer()
            Text("\(count)").font(.system(size: 13, weight: .bold))
        }
    }
}

struct ReviewForecastCard: View {
    let items: [VocabularyItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Review Forecast")
                .font(.headline)
            
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(0..<4) { day in
                    ForecastBar(count: countFor(day: day), day: dayLabel(day: day))
                }
            }
        }
        .padding(Theme.standardPadding)
        .frame(maxWidth: .infinity, minHeight: 150)
        .background(Theme.glassBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardCornerRadius).stroke(Theme.cardBorder, lineWidth: 1))
    }
    
    func countFor(day: Int) -> Int {
        let calendar = Calendar.current
        let targetDate = calendar.startOfDay(for: calendar.date(byAdding: .day, value: day, to: Date())!)
        return items.filter { item in
            if let next = item.nextReviewAt {
                return calendar.isDate(next, inSameDayAs: targetDate)
            }
            return false
        }.count
    }
    
    func dayLabel(day: Int) -> String {
        if day == 0 { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: Calendar.current.date(byAdding: .day, value: day, to: Date())!)
    }
}

struct ForecastBar: View {
    let count: Int
    let day: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Theme.primaryAccent)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.primaryAccent.opacity(0.2))
                .frame(width: 20, height: CGFloat(min(80, max(6, count))))
            
            Text(day)
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatCard: View {

    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title3.bold())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    DashboardView()
}
