import SwiftUI
import SwiftData

#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
#endif

@main
struct VocabbApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #endif
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            VocabularyItem.self,
            ActivityRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        #if os(macOS)
        Window("Vocabb", id: "main") {
            MainTabView()
                .modelContainer(sharedModelContainer)
        }
        #else
        WindowGroup {
            MainTabView()
                .modelContainer(sharedModelContainer)
        }
        #endif
    }
}
