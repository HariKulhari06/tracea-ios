import SwiftUI
import TraceaCore

@MainActor
final class SettingsViewModel: ObservableObject {
    @AppStorage("enableDebugger") var enableDebugger: Bool = true
    @AppStorage("floatingButton") var floatingButton: Bool = true {
        didSet {
            #if canImport(UIKit)
            FloatingButtonManager.shared.setEnabled(floatingButton)
            #endif
        }
    }
    @AppStorage("captureRequests") var captureRequests: Bool = true
    @AppStorage("showRedactedPlaceholder") var showRedactedPlaceholder: Bool = true
    
    @Published var eventCount: Int = 0
    @Published var storageUsage: String = "0 KB"
    
    @Published var allowedDomains: [String] = []
    @Published var ignoredDomains: [String] = []
    @Published var capturedDomains: [String] = []
    
    init() {
        let currentFilter = TraceaServiceLocator.shared.config.domainFilterConfig
        self.allowedDomains = currentFilter.allowedDomains
        self.ignoredDomains = currentFilter.ignoredDomains
        
        Task {
            await loadStats()
            await loadCapturedDomains()
        }
    }
    
    var domainFilterSummary: String {
        if !allowedDomains.isEmpty {
            return "Capturing requests ONLY for \(allowedDomains.count) allowed domain(s)."
        } else if !ignoredDomains.isEmpty {
            return "Capturing all requests EXCEPT \(ignoredDomains.count) ignored domain(s)."
        } else {
            return "No domain filters active. Capturing all network traffic."
        }
    }
    
    func addAllowedDomain(_ domain: String) {
        let clean = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty, !allowedDomains.contains(clean) else { return }
        allowedDomains.append(clean)
        persistAndNotify()
    }
    
    func removeAllowedDomain(_ domain: String) {
        allowedDomains.removeAll { $0 == domain }
        persistAndNotify()
    }
    
    func addIgnoredDomain(_ domain: String) {
        let clean = domain.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty, !ignoredDomains.contains(clean) else { return }
        ignoredDomains.append(clean)
        persistAndNotify()
    }
    
    func removeIgnoredDomain(_ domain: String) {
        ignoredDomains.removeAll { $0 == domain }
        persistAndNotify()
    }
    
    private func persistAndNotify() {
        UserDefaults.standard.set(allowedDomains, forKey: "tracea_allowed_domains")
        UserDefaults.standard.set(ignoredDomains, forKey: "tracea_ignored_domains")
        
        TraceaServiceLocator.shared.config.domainFilterConfig.allowedDomains = allowedDomains
        TraceaServiceLocator.shared.config.domainFilterConfig.ignoredDomains = ignoredDomains
        
        NotificationCenter.default.post(name: Notification.Name("TraceaDomainFilterChanged"), object: nil)
    }
    
    func loadCapturedDomains() async {
        if let store = TraceaServiceLocator.shared.store {
            for await events in store.getAll() {
                let hosts = Set(events.map { $0.host.lowercased() }.filter { !$0.isEmpty })
                self.capturedDomains = hosts.sorted()
                break
            }
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
