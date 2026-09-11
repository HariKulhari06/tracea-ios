import Foundation

/// Notification names for MockEngine updates
public extension Notification.Name {
    static let TraceaMockRulesChanged = Notification.Name("TraceaMockRulesChanged")
    static let TraceaMockingStateChanged = Notification.Name("TraceaMockingStateChanged")
}

/// Manages mocking rules for network requests.
public final class MockEngine: @unchecked Sendable {
    public static let shared = MockEngine()
    
    private let lock = NSLock()
    private var _rules: [MockRule] = []
    private var _mockingEnabled: Bool = false
    private var directoryURL: URL?
    
    public var rules: [MockRule] {
        lock.lock()
        defer { lock.unlock() }
        return _rules
    }
    
    public var mockingEnabled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _mockingEnabled
    }
    
    private init() {}
    
    /// Initializes the MockEngine with a directory to persist rules.
    public func initialize(directory: URL) {
        lock.lock()
        self.directoryURL = directory
        lock.unlock()
        loadRules()
    }
    
    /// Enables or disables mocking.
    public func setMockingEnabled(_ enabled: Bool) {
        lock.lock()
        _mockingEnabled = enabled
        lock.unlock()
        NotificationCenter.default.post(name: .TraceaMockingStateChanged, object: nil)
    }
    
    /// Adds a new mock rule.
    public func addRule(_ rule: MockRule) {
        lock.lock()
        _rules.append(rule)
        lock.unlock()
        saveRules()
        NotificationCenter.default.post(name: .TraceaMockRulesChanged, object: nil)
    }
    
    /// Removes a mock rule by ID.
    public func removeRule(id: String) {
        lock.lock()
        _rules.removeAll { $0.id == id }
        lock.unlock()
        saveRules()
        NotificationCenter.default.post(name: .TraceaMockRulesChanged, object: nil)
    }
    
    /// Updates an existing mock rule.
    public func updateRule(_ rule: MockRule) {
        lock.lock()
        if let index = _rules.firstIndex(where: { $0.id == rule.id }) {
            _rules[index] = rule
        }
        lock.unlock()
        saveRules()
        NotificationCenter.default.post(name: .TraceaMockRulesChanged, object: nil)
    }
    
    /// Finds a matching mock rule for a given URL and HTTP method.
    public func matchRule(url: String, method: HttpMethod) -> MockRule? {
        lock.lock()
        defer { lock.unlock() }
        
        guard _mockingEnabled else { return nil }
        
        return _rules.first { rule in
            guard rule.enabled else { return false }
            guard rule.method == .unknown || rule.method == method else { return false }
            
            do {
                let regex = try NSRegularExpression(pattern: rule.pathPattern, options: [])
                let range = NSRange(location: 0, length: url.utf16.count)
                return regex.firstMatch(in: url, options: [], range: range) != nil
            } catch {
                return url.contains(rule.pathPattern)
            }
        }
    }
    
    private func saveRules() {
        guard let dirURL = directoryURL else { return }
        lock.lock()
        let currentRules = _rules
        lock.unlock()
        
        let fileURL = dirURL.appendingPathComponent("mock_rules.json")
        do {
            let data = try JSONEncoder().encode(currentRules)
            try data.write(to: fileURL)
        } catch {
            print("Tracea: Failed to save mock rules - \(error)")
        }
    }
    
    private func loadRules() {
        guard let dirURL = directoryURL else { return }
        let fileURL = dirURL.appendingPathComponent("mock_rules.json")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let loadedRules = try JSONDecoder().decode([MockRule].self, from: data)
            lock.lock()
            _rules = loadedRules
            lock.unlock()
            NotificationCenter.default.post(name: .TraceaMockRulesChanged, object: nil)
        } catch {
            print("Tracea: Failed to load mock rules - \(error)")
        }
    }
}
