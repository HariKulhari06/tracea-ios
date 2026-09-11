import SwiftUI
import TraceaCore

@MainActor
final class MockRulesViewModel: ObservableObject {
    @Published var rules: [MockRule] = []
    @Published var mockingEnabled = false
    @Published var capturedPaths: [String] = []
    
    init() {
        self.rules = MockEngine.shared.rules
        self.mockingEnabled = MockEngine.shared.mockingEnabled
        
        NotificationCenter.default.addObserver(forName: Notification.Name("TraceaMockRulesChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.rules = MockEngine.shared.rules
            }
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name("TraceaMockingStateChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.mockingEnabled = MockEngine.shared.mockingEnabled
            }
        }
        
        Task {
            if let store = TraceaServiceLocator.shared.store {
                for await eventsList in store.getAll() {
                    self.capturedPaths = Array(Set(eventsList.map { $0.path })).sorted()
                }
            }
        }
    }
    
    func toggleMocking() {
        MockEngine.shared.setMockingEnabled(!mockingEnabled)
    }
    
    func addRule(_ rule: MockRule) {
        MockEngine.shared.addRule(rule)
    }
    
    func removeRule(id: String) {
        MockEngine.shared.removeRule(id: id)
    }
    
    func updateRule(_ rule: MockRule) {
        MockEngine.shared.updateRule(rule)
    }
    
    func getResponseBodyForPath(_ path: String) -> String? {
        return nil
    }
}
