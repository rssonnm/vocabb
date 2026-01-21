import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)
            
            VocabBankView()
                .tabItem {
                    Label("My Vocab", systemImage: "book.fill")
                }
                .tag(1)
            
            PracticeView()
                .tabItem {
                    Label("Practice", systemImage: "graduationcap.fill")
                }
                .tag(2)
            
            VocabGraphView()
                .tabItem {
                    Label("Map", systemImage: "circle.grid.3x3.fill")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}

#Preview {
    MainTabView()
}
