// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Vocabb",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .executable(name: "Vocabb", targets: ["Vocabb"])
    ],
    targets: [
        .executableTarget(
            name: "Vocabb",
            path: ".",
            exclude: ["Resources"],
            sources: [
                "VocabbApp.swift",
                "Theme.swift",
                "Models/VocabularyItem.swift",
                "Models/ActivityRecord.swift",
                "ViewModels/PracticeViewModel.swift",
                "ViewModels/QuizViewModel.swift",
                "Services/AudioService.swift",
                "Services/CSVImporter.swift",
                "Views/MainTabView.swift",
                "Views/DashboardView.swift",
                "Views/VocabBankView.swift",
                "Views/AddVocabView.swift",
                "Views/VocabDetailView.swift",
                "Views/PracticeView.swift",
                "Views/QuizView.swift",
                "Views/VocabGraphView.swift",
                "Views/SettingsView.swift",
                "Views/ActivityHeatmapView.swift"
            ]
        )
    ]
)
