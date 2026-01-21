import SwiftUI
import SwiftData

struct ActivityHeatmapView: View {
    @Query(sort: \ActivityRecord.date) private var allActivities: [ActivityRecord]
    
    private let calendar = Calendar.current
    private let columns = 28 // Increased for better span
    private let daysInWeek = 7
    
    private var activityMap: [Date: Int] {
        var map: [Date: Int] = [:]
        for activity in allActivities {
            map[activity.date, default: 0] += activity.count
        }
        return map
    }
    
    private var startOfCurrentWeek: Date {
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        return calendar.date(from: components)!
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerRow
            
            HStack(alignment: .top, spacing: 8) {
                // Weekday Labels - Aligned with rows 1, 3, 5 (Mon, Wed, Fri)
                VStack(spacing: 4) {
                    Text("").frame(height: 14) // Alignment with month labels row
                    Group {
                        Text("").frame(height: 14) // Sun
                        weekdayLabel("Mon")
                        Text("").frame(height: 14) // Tue
                        weekdayLabel("Wed")
                        Text("").frame(height: 14) // Thu
                        weekdayLabel("Fri")
                        Text("").frame(height: 14) // Sat
                    }
                }
                .padding(.top, 24)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        // Month Labels Row
                        monthLabelsRow
                        
                        // The Grid
                        HStack(spacing: 4) {
                            ForEach(0..<columns, id: \.self) { column in
                                VStack(spacing: 4) {
                                    ForEach(0..<daysInWeek, id: \.self) { day in
                                        let date = dateFor(column: column, day: day)
                                        let count = activityMap[date] ?? 0
                                        let isFuture = date > calendar.startOfDay(for: Date())
                                        
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(isFuture ? Color.clear : colorForCount(count))
                                            .frame(width: 14, height: 14)
                                            .overlay(
                                                Group {
                                                    if !isFuture {
                                                        RoundedRectangle(cornerRadius: 3)
                                                            .stroke(Color.black.opacity(0.05), lineWidth: 0.5)
                                                    }
                                                }
                                            )
                                            .help("\(count) activities on \(date.formatted(date: .long, time: .omitted))")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(24)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Theme.cardBorder, lineWidth: 1)
        )
    }
    
    private var monthLabelsRow: some View {
        HStack(spacing: 4) {
            ForEach(0..<columns, id: \.self) { column in
                let date = dateFor(column: column, day: 0)
                let month = monthLabel(for: date, column: column)
                
                Text(month)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 14, alignment: .leading)
                    .fixedSize(horizontal: true, vertical: false) // Prevent wrapping
            }
        }
    }
    
    private var headerRow: some View {
        HStack {
            Text("Study Activity")
                .font(.headline)
            Spacer()
            HStack(spacing: 4) {
                Text("Less")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                
                ForEach(0..<5) { level in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(colorForLevel(level))
                        .frame(width: 10, height: 10)
                }
                
                Text("More")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func weekdayLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 9))
            .foregroundStyle(.secondary.opacity(0.7))
            .frame(height: 14)
    }
    
    private func monthLabel(for date: Date, column: Int) -> String {
        let month = calendar.component(.month, from: date)
        
        // Always show for the first column
        if column == 0 {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }
        
        // Show if this column is the start of a new month
        let prevColumnDate = dateFor(column: column - 1, day: 0)
        let prevMonth = calendar.component(.month, from: prevColumnDate)
        
        // Also check if the month starts mid-week in this column
        let columnEndDate = dateFor(column: column, day: 6)
        let columnEndMonth = calendar.component(.month, from: columnEndDate)
        
        if month != prevMonth || (month != columnEndMonth && columnEndMonth == month) {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM"
            return formatter.string(from: date)
        }
        
        return ""
    }
    
    private func dateFor(column: Int, day: Int) -> Date {
        let weeksBack = (columns - 1) - column
        let startOfColumnWeek = calendar.date(byAdding: .weekOfYear, value: -weeksBack, to: startOfCurrentWeek)!
        return calendar.date(byAdding: .day, value: day, to: startOfColumnWeek)!
    }
    
    private func colorForCount(_ count: Int) -> Color {
        if count == 0 { return Color.secondary.opacity(0.08) }
        if count < 5 { return Color.red.opacity(0.2) }
        if count < 10 { return Color.red.opacity(0.4) }
        if count < 20 { return Color.red.opacity(0.7) }
        return Color.red
    }
    
    private func colorForLevel(_ level: Int) -> Color {
        switch level {
        case 0: return Color.secondary.opacity(0.08)
        case 1: return Color.red.opacity(0.2)
        case 2: return Color.red.opacity(0.4)
        case 3: return Color.red.opacity(0.7)
        default: return Color.red
        }
    }
}

#Preview {
    ActivityHeatmapView()
}
