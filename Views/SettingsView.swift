import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Storage Location")
                                .font(.headline)
                            Text("Local Device (SwiftData)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "internaldrive.fill")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Data & Storage")
                } footer: {
                    Text("Your vocabulary is stored securely and locally on this device.")
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label("Clear All Vocabulary", systemImage: "trash.fill")
                    }
                } header: {
                    Text("Danger Zone")
                }
                
                Section {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            #if os(macOS)
            .frame(minWidth: 400, minHeight: 300)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Xác nhận xoá sạch dữ liệu?", isPresented: $showingDeleteConfirmation) {
                Button("Xoá tất cả", role: .destructive) {
                    clearAllData()
                }
                Button("Hủy", role: .cancel) {}
            } message: {
                Text("Hành động này sẽ xoá tất cả từ vựng và tiến trình học của bạn. Bạn không thể hoàn tác.")
            }
        }
    }
    
    private func clearAllData() {
        do {
            try modelContext.delete(model: VocabularyItem.self)
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to clear data: \(error)")
        }
    }
}

#Preview {
    SettingsView()
}
