import SwiftUI
import TraceaCore

@MainActor
final class MockRulesViewModel: ObservableObject {
    @Published var rules: [MockRule] = []
    @Published var mockingEnabled = false
    @Published var capturedPaths: [String] = []
    
    @Published var events: [NetworkEvent] = []
    
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
                    self.events = eventsList
                    self.capturedPaths = Array(Set(eventsList.map { $0.path })).filter { !$0.isEmpty }.sorted()
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
    
    func getResponseBodyForPath(_ rawPath: String) async -> String? {
        let cleanPath = rawPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanPath.isEmpty else { return nil }
        
        // Check current cached events first, sorted by most recent
        let candidateEvents = events.sorted { $0.timestamp > $1.timestamp }
        
        // Try exact path match first, then case-insensitive, then suffix/contains
        let matchingEvent = candidateEvents.first { event in
            guard event.responseBody != nil else { return false }
            return event.path == cleanPath ||
                   event.path.lowercased() == cleanPath.lowercased() ||
                   cleanPath.contains(event.path) ||
                   event.path.contains(cleanPath) ||
                   event.url.contains(cleanPath)
        }
        
        guard let body = matchingEvent?.responseBody else { return nil }
        switch body {
        case .text(let content, _, _):
            return content
        case .fileReference(let path, _, _):
            return try? String(contentsOfFile: path, encoding: .utf8)
        case .truncated(let actualSize, _, _):
            return "[Response was truncated (\(actualSize) bytes)]"
        case .binary(let size, let contentType):
            return "[Binary \(contentType.rawValue): \(size) bytes]"
        }
    }
}
