import Foundation

/// Manages the current debugging session.
public final class DebuggerSession: @unchecked Sendable {
    public static let shared = DebuggerSession()
    
    private var lock = NSLock()
    
    private var _sessionId: String
    private var _sessionName: String
    
    public var sessionId: String {
        lock.lock()
        defer { lock.unlock() }
        return _sessionId
    }
    
    public var sessionName: String {
        lock.lock()
        defer { lock.unlock() }
        return _sessionName
    }
    
    private init() {
        let newId = UUID().uuidString
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy HH:mm:ss"
        let newName = "Session " + formatter.string(from: date)
        
        self._sessionId = newId
        self._sessionName = newName
    }
    
    /// Starts a new debugging session, updating the session ID and name.
    public func startNewSession() {
        lock.lock()
        defer { lock.unlock() }
        
        _sessionId = UUID().uuidString
        
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy HH:mm:ss"
        _sessionName = "Session " + formatter.string(from: date)
    }
}
