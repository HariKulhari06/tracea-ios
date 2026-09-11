import SwiftUI
import TraceaCore

@MainActor
final class SettingsViewModel: ObservableObject {
    @AppStorage("enableDebugger") var enableDebugger: Bool = true
    @AppStorage("floatingButton") var floatingButton: Bool = true
    @AppStorage("captureRequests") var captureRequests: Bool = true
    @AppStorage("showRedactedPlaceholder") var showRedactedPlaceholder: Bool = true
    
    @Published var eventCount: Int = 0
    @Published var storageUsage: String = "0 KB"
    
    init() {
        Task {
            await loadStats()
        }
    }
    
    func loadStats() async {
        if let store = TraceaServiceLocator.shared.store {
            self.eventCount = await store.getCount()
            self.storageUsage = SizeFormatter.format(bytes: Int64(eventCount * 1024))
        }
    }
    
    func clearAllData() async {
        if let store = TraceaServiceLocator.shared.store {
            await store.clear()
            await loadStats()
        }
    }
}
